import os
import re
from flask import Flask, render_template, request, redirect, url_for, flash
import extract_insert as ei
import validate as v


app = Flask(__name__)


@app.route('/dashboard/')
def dashboard():
    return render_template('index.html')


@app.route('/cluster_verify/', methods=['GET', 'POST'])
def cluster_verify():
    if request.method == 'POST':
        cluster = request.form['cname'].encode('utf8')

        # Access NetApp API's and connect to a cluster
        server = ei.login_naserver(cluster)

        # Make a function call to extract and insert data
        print 'Data extraction and insertion is in progress'
        ei.data_extraction(cluster, server)
        print 'Data extraction and insertion is complete'

        # Make a function call to verify data
        print 'Data verification is in progress'
        v.data_validation(cluster)
        print 'Data verification is complete'

        return render_template('cluster_verify.html',
                               cluster=cluster, output_dict=v.output_dict)

    else:
        return render_template('cluster_verify.html')


@app.route('/smart_stars/', methods=['GET', 'POST'])
def smart_stars():
    '''Get data here'''
    fields = []

    # Change to log directory
    os.chdir(config.stars_dir)

    if request.method == 'POST':
        log_file = request.form['name'].encode('utf8')
        # request.form['placeholder'] = log_file

        try:
            with open(log_file, 'r') as f:
                lines = f.readlines()
                for line in lines:
                    fields.append(re.split(' |,|\r\n', line))

            if not fields:
                error_message = 'No data available in \'$s\' file' % log_file
                flash(error_message)

            return render_template('smart_stars.html',
                                   tbody=fields,
                                   file=log_file)

        # parent of IOError, OSError *and* WindowsError where available
        except EnvironmentError:
            error_message = 'Error accessing file: \n \'%s\' file.' % log_file
            print error_message
            flash(error_message)
            return render_template('smart_stars.html')

    else:
        return render_template('smart_stars.html')


if __name__ == '__main__':
    app.secret_key = 'super secret key'
    app.config['SESSION_TYPE'] = 'filesystem'
    app.debug = True
    app.run(host='0.0.0.0', port=5000)
