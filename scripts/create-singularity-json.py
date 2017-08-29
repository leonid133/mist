import json
import sys
import os


def exclusive(singularity_config, hash_id):
    singularity_config['deploy']['env']['MIST_WORKER_NAME'] = os.environ['MIST_WORKER_NAME']
    singularity_config['deploy']['env']['MIST_WORKER_CONTEXT'] = os.environ['MIST_WORKER_CONTEXT']

    singularity_config['deploy']['env']['MIST_WORKER_MODE'] = os.environ['MIST_WORKER_MODE']
    singularity_config['deploy']['env']['MIST_WORKER_JAR_PATH'] = os.environ['MIST_WORKER_JAR_PATH']
    singularity_config['deploy']['env']['MIST_WORKER_RUN_OPTIONS'] = os.environ['MIST_WORKER_RUN_OPTIONS']

    singularity_config['id'] = singularity_config['id'] + '-' + hash_id 
    
    return singularity_config
    

def main():
    template_json_path = "%s/configs/pca-mist-worker.json" % os.environ['MIST_HOME']
    hash_id = sys.argv[1]
    
    with open(template_json_path) as template:
        singularity_config = json.load(template)
        exclusive_json = exclusive(singularity_config, hash_id)
    
    print exclusive_json
    
    exclusive_json_path = "%s/configs/pca-mist-worker-%s.json" % (os.environ['MIST_HOME'], hash_id)
    with open(exclusive_json_path, "wb") as f:
        f.write(json.dumps(exclusive_json,
                      indent=4, sort_keys=True,
                      separators=(',', ': '), ensure_ascii=False))
    
if __name__ == '__main__':
    main()
