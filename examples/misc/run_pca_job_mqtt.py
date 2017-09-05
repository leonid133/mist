#!/usr/bin/python

import paho.mqtt.client as mqtt
import json
import uuid

import sys
import os

class MqttJobRunner:

    def __init__(self, host, port, topic_in, topic_out):
        self.topic_in = topic_in
        self.topic_out = topic_out

        def on_connect(client, userdata, flags, rc):
            print("Mqtt client connected")
        
        def await_init(data):
            if data["event"] == "initialized" and data["externalId"] == self.externalId:
              self.jobId = data["id"]
              self.status = data["event"]
              print("Job is started with id:" + self.jobId)

        def await_result(data):
            if data["id"] == self.jobId:
                event = data["event"]
                if event == "finished":
                    self.success = True
                    self.finished = True
                    self.result = data["result"]
                elif event == "failed":
                    self.success = False
                    self.finished = True
                    self.result = data
                elif event == "canceled":
                    self.success = False
                    self.finished = True
                    self.result = data
                elif event == "logs":
                    for line in data["events"]:
                        print("Log:" + line["message"])

        def on_message(client, userdata, msg):
            data = json.loads(msg.payload)
            if self.status == "unknown":
                await_init(data)
            else:
                await_result(data)


        mqttc = mqtt.Client()
        mqttc.on_connect = on_connect
        mqttc.on_message = on_message
        mqttc.connect(host, port)
        mqttc.subscribe(self.topic_out, 0)
        self.mqttc = mqttc



    def runJob(self, endpoint, params, runSettings = { "workerId": "default" }):
        self.externalId = str(uuid.uuid4())
        req = {
          "endpointId": endpoint,
          "parameters": params,
          "externalId": self.externalId,
          "runSettings": runSettings
        }
        self.mqttc.publish(self.topic_in, json.dumps(req)) 
        self.status = "unknown"
        self.finished = False
        while not self.finished:
            self.mqttc.loop(1)

        # Await logs
        for x in range(0,3):
            self.mqttc.loop(1)

        if self.success:
            return self.result
        else:
            raise Exception("Job "+ endpoint + " jobId:" + self.jobId + "failed. Reason:" + self.result)





runner = MqttJobRunner("rabbitmq.9dev.io", 1883, "pca_mist_sub", "pca_mist_pub")

runSettings = { "workerId": "lblokhin" }

json_path = "/nethome/lblokhin/git/mist_latest/mist/examples/misc/aip_tiffany_filters_off.json"


with open(json_path) as parameters_json:
        parameters = json.load(parameters_json)
        methods = (parameters['method']['name']).split(",")
        method_to_endpoint = {
            'Create_Ref_Tables': 'pca-create-ref-tables',
            'filter_IDA_task': 'pca-filter-ida-task',
            'filter_CA_events_task': 'pca-filter-ca-event-task',
            'filter_events_task': 'pca-filter-events-task',
            'write_new_events': 'pca-write-new-events',
            'filter_ref_tables': 'pca-filter-ref-tables',
            'PCA_run_task': 'pca-run-task',
            'output_taskAll': 'pca-output-task',
            'EventLogTracking': 'pca-event-log-tracking',
            'TestParaccel': 'pca-test-paraccel'
        }
        for method in methods:
            print("Start method: %s on endpoint %s" % (method, method_to_endpoint[method]))
            parameters['method']['name'] = method
            result = runner.runJob(method_to_endpoint[method], { "parameters": parameters }, runSettings)
            print("Job result is:" + json.dumps(result))
