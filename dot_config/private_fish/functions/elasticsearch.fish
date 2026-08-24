function elasticsearch
    cd ~/elasticsearch
    env ES_JAVA_OPTS="-Xms1g -Xmx1g" ES_JAVA_HOME="/opt/homebrew/Cellar/openjdk/23.0.2/libexec/openjdk.jdk/Contents/Home" ./bin/elasticsearch
end
