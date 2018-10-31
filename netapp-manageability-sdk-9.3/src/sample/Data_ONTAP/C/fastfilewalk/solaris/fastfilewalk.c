//============================================================//
//                                                            //
// $ID$                                                       //
//                                                            //
// fastfilewalk.cpp                                           //
//                                                            //
// sample threaded directory traversal code for fast          //
// filesystem walking from Solaris applications               //                                                            //
//                                                            //
// Copyright 2002-2003 Network Appliance, Inc. All rights     //
// reserved. Specifications subject to change without notice. // 
//                                                            //
// This SDK sample code is provided AS IS, with no support or //
// warranties of any kind, including but not limited to       //
// warranties of merchantability or fitness of any kind,      //
// expressed or implied.  This code is subject to the license //
// agreement that accompanies the SDK.                        //
//                                                            //
// tab size = 4                                               //
//                                                            //
//============================================================//

//234567890123456789012345678901234567890123456789012345678901234567890123456789

//============================================================//
//
// Notes on performance of this code
//
// Informal tests show that performance increases tail off at
// about 5 threads over a gigabit LAN.  We recorded around
// 10000 NFS ops per second at peak activity.
//
//============================================================//

//
// Usage : fastfilewalk path [num_threads]
//
//      path - path to be walked
//      num_threads - number of threads to use to walk the given 
//          path, 10 if not supplied.
//
// [num_threads] threads are initially created, all waiting on an 
// empty stack (queue in the code).  The given path is then put 
// in the stack.  One of the waiting threads will pick it up and 
// walk the directory putting any sub directories in the stack, and
// processing files as they're encountered.  The other waiting threads 
// pick up the new entries in the stack and do the same.  Note, 
// symlinks are not followed.  lstat is ran for every file/symlink/dir.
//

#include <sys/types.h>
#include <sys/stat.h>
#include <time.h>
#include <dirent.h>
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <thread.h>
#include <sched.h>
#include <math.h>
#include <errno.h>
#include <string.h>

#define DEBUG 0
#define DIR_INTERVAL 1000
#define DEF_MAX_THREADS 10
#define MAX_PATH_LEN 2048
#define MAX_QUEUE_SIZE 1024

#define EXIT(msg) {fprintf(stderr, msg); \
                     exit(1);}
#define ASSERT(exp) if (!(exp)) EXIT("ASSERT\n");
#define get_free_thread() dequeue();

//============================================================//

#define INLINE inline
#define STATIC static

//
// status counters and timers
//
STATIC int file_count = 0;
STATIC int dir_count = 0;
STATIC int link_count = 0;
STATIC int other_count = 0;
STATIC long long total_size = 0;
STATIC int threads_created = 0;
STATIC time_t start_time;

//
// thread vars
//
STATIC int thread_count = 0;
STATIC pthread_t* tids = NULL;
STATIC int max_threads = DEF_MAX_THREADS;

//
// mutex for counters and queue
//
STATIC pthread_mutex_t thread_counter_mutex;
STATIC pthread_mutex_t queue_mutex;
STATIC pthread_mutex_t counter_mutex;
STATIC pthread_mutex_t dir_counter_mutex;
STATIC pthread_mutex_t file_counter_mutex;
STATIC pthread_mutex_t link_counter_mutex;
STATIC pthread_mutex_t other_counter_mutex;

STATIC pthread_cond_t queue_nonempty_cond;
STATIC pthread_cond_t queue_nonfull_cond;


//
// queue vars
//
STATIC int threads_waiting_nonempty_count = 0;
STATIC char* queue[MAX_QUEUE_SIZE];
STATIC int que_head;
STATIC int que_active = 0;

//============================================================//
//
// forward function declarations
//
STATIC void summary(void);
STATIC void* thread_walk_work(void*);
INLINE STATIC void create_thread_walk(char*);

//============================================================//
//
// queue - it is actually a stack - utility functions
//
//============================================================//

//
// initializes the queue, must be called before any queue operations
//
INLINE STATIC void init_queue(void)
{
	pthread_mutex_lock(&queue_mutex);
	que_head = 0;
	que_active = 1;
	pthread_mutex_unlock(&queue_mutex);
}

//============================================================//
//
// finalizes the queue, must be called when finished with the queue
//
INLINE STATIC void fin_queue(void)
{
	pthread_mutex_lock(&queue_mutex);
	que_active = 0;
	//
	// broadcast to everyone waiting on the queue, that the queue 
	// is inactive
	//
	pthread_cond_broadcast(&queue_nonempty_cond);
	pthread_cond_broadcast(&queue_nonfull_cond);
	pthread_mutex_unlock(&queue_mutex);
}

//============================================================//

//
// get the number of threads waiting for the queue to be none empty
//
INLINE STATIC int get_thread_waiting_nonempty_count()
{
	int count;
	pthread_mutex_lock(&queue_mutex);
	count = threads_waiting_nonempty_count;
	pthread_mutex_unlock(&queue_mutex);
	return count;
}

//============================================================//

//
// returns non-zero if queue is full, 0 otherwise
//
INLINE STATIC int is_queue_full(void)
{
	int ret;

	pthread_mutex_lock(&queue_mutex);
	ret = (que_head == MAX_QUEUE_SIZE);
	pthread_mutex_unlock(&queue_mutex);
	return ret;
}

//============================================================//

//
// returns non-zero if queue is empty, 0 otherwise
//
INLINE STATIC int is_queue_empty(void)
{
	int ret;

	pthread_mutex_lock(&queue_mutex);
	ret = (que_head == 0);
	pthread_mutex_unlock(&queue_mutex);
	return ret;
}

//============================================================//

//
// Put item on top of queue, wait for the queue to be not full 
// if it is.  Exit and do nothing if the queue is inactive or has 
// become inactive while waiting for the queue to be not full.
//
INLINE STATIC void enqueue(char* item)
{
	pthread_mutex_lock(&queue_mutex);
        while (que_head == MAX_QUEUE_SIZE) { // the queue is full 
		if (!que_active) {
			goto out;
		}
		pthread_cond_wait(&queue_nonfull_cond, &queue_mutex);
	}
	queue[que_head] = item;
	que_head ++;
	pthread_cond_broadcast(&queue_nonempty_cond);
out:	
	pthread_mutex_unlock(&queue_mutex);
}

//============================================================//

//
// get top item from the queue (stack). waits for the queue to be non-empty if it is.
// exits and do nothing if the queue is not active or has become inactive,
// while waiting for the queue to be not empty.
//
INLINE STATIC char* dequeue(void)
{
	char* ret;
	
	pthread_mutex_lock(&queue_mutex);
	while (que_head == 0) {			// the queue is empty 
		if (!que_active) {
			ret = NULL;
			goto out;
		}
		threads_waiting_nonempty_count ++;
		pthread_cond_wait(&queue_nonempty_cond, &queue_mutex);
		threads_waiting_nonempty_count --;
	}
	que_head --;
	ret = queue[que_head];
	pthread_cond_broadcast(&queue_nonfull_cond);
out:	
	pthread_mutex_unlock(&queue_mutex);
	return ret;
}

//============================================================//

//
// increment counter
//
INLINE STATIC void inc_count(pthread_mutex_t* mutex, int* counter)
{
	pthread_mutex_lock(mutex);
	(*counter)++;
	pthread_mutex_unlock(mutex);
}

//============================================================//

//
// add to counter
//
INLINE STATIC void add_count(pthread_mutex_t* mutex, long long* total, 
				off_t size)
{
	pthread_mutex_lock(mutex);
	(*total) += size;
	pthread_mutex_unlock(mutex);
}

//============================================================//

//
// recursively walk the directory pointed to by path.
//
STATIC void recursive_walk(char* path)
{
	struct dirent	dirp;
	struct stat	mystat;
	struct dirent*	result = NULL;
	char		childname[MAX_PATH_LEN];
	int		err;
	DIR*		dp;

	dp = opendir(path);
	if (dp == NULL) {
		fprintf(stdout, "can't open %s\n", path);
		return;
	}

	err = readdir_r(dp, &dirp, &result);
	while (result) {
		if ((strcmp(result->d_name, ".") != 0) && 
		    (strcmp(result->d_name, "..") != 0)) {
			sprintf(childname, "%s/%s", path, result->d_name);
			err = lstat(childname, &mystat);
			if (S_ISREG(mystat.st_mode)) {
				inc_count(&file_counter_mutex, &file_count);
				add_count(&file_counter_mutex, &total_size, 
								mystat.st_size);
			} else if (S_ISLNK(mystat.st_mode)) {
				inc_count(&link_counter_mutex, &link_count);
			} else if (S_ISDIR(mystat.st_mode)) {
				inc_count(&dir_counter_mutex, &dir_count);
				create_thread_walk(childname);
			} else {
				inc_count(&other_counter_mutex, &other_count);
			}
		}
		err = readdir_r(dp, &dirp, &result);
	}

	closedir(dp);
}

//============================================================//

//
// working function for all threads, which waits for any entries 
// in the queue and walks it.
//
STATIC void* thread_walk_work(void* md) {
	while (1) {
		char* path = dequeue(); // wait for entry 
		if (path == NULL) {
			// walk done 
			break;
		}
		recursive_walk(path);
		free(path);
		if (is_queue_empty() && (get_thread_waiting_nonempty_count()
						 == max_threads - 1)) {
			// I'm the last active thread, done walking 
			fin_queue();
		}
	}
}

//============================================================//

//
// decides what to do with a director, if the queue is not full, 
// add it to the queue and let some other thread walk it.  If the 
// queue is full, then all threads are already busy, so just walk 
// the path yourself.
//
INLINE STATIC void create_thread_walk(char* path) {
	if (!is_queue_full()) { 
		enqueue(strdup(path));
	} else {
		//			
		// queue is full, don't enqueue the entry, just 
		// walk it directly 
		//
		recursive_walk(path);
	}
}

//============================================================//

//
// prints out the summary so far
//
STATIC void summary(void)
{
	fprintf(stdout, "%d files totaling ", file_count);
	fprintf(stdout, "%lld bytes (%lld MB)\n", total_size, 
				(total_size /( 1024 * 1024)));
	fprintf(stdout, "%d sym links\n", link_count);
	fprintf(stdout, "%d others\n", other_count);
	fprintf(stdout, "%d directories\n", dir_count);
}

//============================================================//

//
// initializes the directory walk variables, must be called before 
// any function in this file.
//
STATIC void initialize_walk(void)
{
	int i;
	int err;

	// init all the mutexes 
	pthread_mutex_init(&thread_counter_mutex, NULL);
	pthread_mutex_init(&queue_mutex, NULL);
	pthread_mutex_init(&counter_mutex, NULL);
	pthread_mutex_init(&dir_counter_mutex, NULL);
	pthread_mutex_init(&file_counter_mutex, NULL);
	pthread_mutex_init(&link_counter_mutex, NULL);
	pthread_mutex_init(&other_counter_mutex, NULL);
	pthread_cond_init(&queue_nonempty_cond, NULL);
	pthread_cond_init(&queue_nonfull_cond, NULL);

	// create all the threads 
	init_queue();
	tids = (pthread_t*) malloc(sizeof(pthread_t) * max_threads);
	for (i = 0; i < max_threads; i++) {
		err = pthread_create(&tids[i], 0, thread_walk_work, NULL);
		if (err) {
			fprintf(stderr, "thread %d : can not create thread,\
						error %d\n", i, err);
		}
	}
	
	// start timer 
	start_time = time(NULL);
}

//============================================================//

//
// called by main thread to wait for all processing threads
//
INLINE STATIC void wait_for_threads(void)
{
	int	i;
	void*	ret;

	for (i = 0; i < max_threads; i++) {
		pthread_join(tids[i], &ret);
	}
}

//============================================================//

//
// finalize use to wait for all processing threads and cleanup
//
STATIC void finalize_walk(void)
{
	int	tdiff;
	time_t	end_time;

	wait_for_threads();
	end_time = time(NULL);

	pthread_mutex_destroy(&thread_counter_mutex);
	pthread_mutex_destroy(&counter_mutex);
	pthread_mutex_destroy(&queue_mutex);
	pthread_mutex_destroy(&dir_counter_mutex);
	pthread_mutex_destroy(&file_counter_mutex);
	pthread_mutex_destroy(&link_counter_mutex);
	pthread_mutex_destroy(&other_counter_mutex);
	pthread_cond_destroy(&queue_nonempty_cond);
	pthread_cond_destroy(&queue_nonfull_cond);

	fprintf(stdout, "--------------- WALK FINISHED ---------------\n");
	summary();
	tdiff = difftime(end_time, start_time);
	fprintf(stdout, "%d second(s) taken\n", tdiff);

	free(tids);
}

//============================================================//

STATIC void usage(void)
{
	printf("Usage : fastfilewalk path [# of threads]\n");
}

//============================================================//

int main(int argc, char* argv[])
{
	if ((argc < 2) || (argc > 3)){
		usage();
		exit(1);
	}
	if (argc == 3) {
		max_threads = atoi(argv[2]);
		if (max_threads < 1) {
			max_threads = DEF_MAX_THREADS;
		}
	}
	initialize_walk();
	create_thread_walk(argv[1]);
	finalize_walk();
	exit(0);
}

//============================================================//
//============================================================//
//============================================================//
