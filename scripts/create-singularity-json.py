import json
import sys
import os


def exclusive(singularity_config, namespace, config, jar, repositories, packages, exclude_packages, jars, hash_id):
    singularity_config['deploy']['arguments'].append(namespace)
    singularity_config['deploy']['arguments'].append(config)
    singularity_config['deploy']['arguments'].append(jar)
    #singularity_config['deploy']['arguments'].append(repositories)
    singularity_config['deploy']['arguments'].append(packages)
    singularity_config['deploy']['arguments'].append(exclude_packages)
    #singularity_config['deploy']['arguments'].append(jars)
    
    singularity_config['id'] = singularity_config['id'] + '-' + hash_id 
    singularity_config['requestType'] = 'RUN_ONCE'

    return singularity_config
    

def main():
    template_json_path = "%s/configs/pca-mist-worker.json" % os.environ['MIST_HOME']
    namespace = sys.argv[1]
    config = sys.argv[2]
    jar = sys.argv[3]
    #repositories = sys.argv[4]
    repositories = ""
    packages = sys.argv[4]
    exclude_packages = sys.argv[5]
    jars = sys.argv[6]
    hash_id = sys.argv[7]
    
    with open(template_json_path) as template:
        singularity_config = json.load(template)
        exclusive_json = exclusive(singularity_config, namespace, config, jar, repositories, packages, exclude_packages, jars, hash_id)
    
    print exclusive_json
    
    exclusive_json_path = "%s/configs/pca-mist-worker-%s.json" % (os.environ['MIST_HOME'], "example")
    with open(exclusive_json_path, "wb") as f:
        f.write(json.dumps(exclusive_json,
                      indent=4, sort_keys=True,
                      separators=(',', ': '), ensure_ascii=False))
    
if __name__ == '__main__':
    main()
