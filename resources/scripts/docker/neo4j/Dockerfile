# Author: Roberto Rodriguez (@Cyb3rWard0g)

FROM neo4j:5.8.0

ENV APOC_VERSION=5.8.0

ENV NEO4J_apoc_export_file_enabled=true
ENV NEO4J_apoc_import_file_enabled=true
ENV NEO4J_apoc_import_file_use__neo4j__config=true
ENV NEO4J_PLUGINS=\[\"apoc\"\]
ENV NEO4J_dbms_security_procedures_unrestricted=apoc.\\\*

ADD https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/download/${APOC_VERSION}/apoc-${APOC_VERSION}-extended.jar $NEO4J_HOME/plugins/

RUN chmod a+r $NEO4J_HOME/plugins/apoc-${APOC_VERSION}-extended.jar

# docker run -it -d --rm --name neo4j -p 7474:7474 -p 7687:7687 -e NEO4J_AUTH=none neo4j-apoc