#!/bin/bash

declare -A categories_order=(
  ["Infrastructure"]=""
  ["Data Management"]=""
  ["Data Storage"]=""
  ["IoT"]=""
  ["Analytics"]=""
  ["Project Management"]=""
  ["ERP"]="" 
  ["AI"]=""
  ["Communication"]=""
  ["Content Management"]=""
  ["Web Development"]=""
  ["Automation and Low-Code"]=""
  ["Scheduling and Collaboration"]=""
  ["Social and Marketing"]=""
  ["Location Services"]=""
  ["Design and Prototyping"]=""
  ["Miscellaneous"]=""
)


declare -A categories_to_emojis=(
  ["Infrastructure"]="🏗️"
  ["IoT"]="📶"
  ["Data Management"]="🗃️"
  ["Data Storage"]="🗄️"
  ["Analytics"]="📊"
  ["Project Management"]="🗂️"
  ["ERP"]="🏢"
  ["AI"]="👾"
  ["Communication"]="💬"
  ["Content Management"]="📚"
  ["Web Development"]="🌐"
  ["Automation and Low-Code"]="🤖"
  ["Scheduling and Collaboration"]="📅"
  ["Social and Marketing"]="📣"
  ["Location Services"]="📍"
  ["Design and Prototyping"]="🎨"
  ["Miscellaneous"]="🧩"
)

declare -A categories_to_stacks
categories_to_stacks=(
  ["Infrastructure"]="monitor elk uptimekuma glpi vaultwarden wuzapi unoapi yourls"
  ["IoT"]="mosquitto nodered"
  ["Data Management"]="pgadmin phpadmin redis_commander delta_lake redisinsight"
  ["Data Storage"]="supabase clickhouse redis pgvector iceberg minio mysql mariadb baserow postgres mongodb weaviate qdrant"
  ["Analytics"]="metabase jupyter_spark airflow"
  ["Project Management"]="openproject focalboard zep twentycrm evolution evolution_lite krayincrm"
  ["ERP"]="odoo"
  ["AI"]="affine ollama anythingllm woofed langflow langfuse"
  ["Communication"]="mosquitto rabbitmq transcrevezap streaming quepasa typebot botpress chatwoot chatwoot_nestor mattermost ntfy"
  ["Content Management"]="documenso docuseal stirlingpdf formbricks moodle outline"
  ["Web Development"]="wordpress directus strapi"
  ["Automation and Low-Code"]="firecrawl n8n dify flowise lowcoder appsmith nocobase nocodb tooljet"
  ["Scheduling and Collaboration"]="easyappointments calcom nextcloud"
  ["Social and Marketing"]="humhub mautic"
  ["Location Services"]="traccar"
  ["Design and Prototyping"]="excalidraw"
  ["Miscellaneous"]="whoami"
)

  # Declare category descriptions
  declare -A categories_descriptions
  categories_descriptions=(
    ["Infrastructure"]="Tools related to managing infrastructure and services, including monitoring, security, and more."
    ["Data Storage"]="Tools for managing and storing data, from databases to storage services."
    ["IoT"]="Tools for working with IoT devices and data."
    ["Data Management"]="Tools for managing and administrating databases."
    ["Analytics"]="Business Intelligence and analytics tools for data analysis and reporting."
    ["Project Management"]="Tools for managing projects, tasks, and team collaboration."
    ["ERP"]="Enterprise Resource Planning and other solutions for managing business operations."
    ["AI"]="AI and Natural Language Processing tools to build and deploy models."
    ["Communication"]="Tools for messaging, communication, and collaboration."
    ["Content Management"]="Tools for managing documents and content in an organization."
    ["Web Development"]="Tools for building and managing websites and web applications."
    ["Automation and Low-Code"]="Automation and low-code platforms for developing applications quickly."
    ["Scheduling and Collaboration"]="Tools for scheduling and team collaboration."
    ["Social and Marketing"]="Social media management and marketing automation tools."
    ["Location Services"]="Tools for location-based services and geospatial data."
    ["Design and Prototyping"]="Design and prototyping tools for visualizing ideas."
    ["Miscellaneous"]="Other useful or unique tools."
  )

declare -A stack_descriptions=(
  ["affine"]="A data science tool for building machine learning models."
  ["clickhouse"]="A columnar database for online analytical processing (OLAP)."
  ["firecrawl"]="A web scraping tool for crawling and extracting data from websites."
  ["elk"]="A collection of tools for Elasticsearch, Logstash, and Kibana."
  ["delta_lake"]="A columnar database for online analytical processing (OLAP)."
  ["langflow"]="An AI tool for managing workflows for large language models (LLMs)."
  ["monitor"]="A system monitoring tool for tracking performance and uptime."
  ["ollama"]="A platform for deploying AI models with ease."
  ["quepasa"]="A chatbot and customer support tool for automating conversations."
  ["woofed"]="A machine learning framework or platform for model training."
  ["dify"]="A platform for automating and managing workflows."
  ["jupyter_spark"]="A notebook environment for Apache Spark and Python."
  ["airflow"]="A workflow automation and scheduling platform."
  ["flowise"]="A low-code platform for automating workflows."
  ["langfuse"]="A platform for integrating large language models into workflows."
  ["moodle"]="An open-source learning management system (LMS)."
  ["openproject"]="A project management tool for collaboration and tracking."
  ["rabbitmq"]="An open-source message broker for handling queues."
  ["transcrevezap"]="A tool for managing WhatsApp message automation."
  ["wordpress"]="A popular content management system (CMS) for building websites."
  ["anythingllm"]="A platform for stable with large language models."
  ["directus"]="An open-source headless CMS for managing content."
  ["focalboard"]="A task and project management tool."
  ["lowcoder"]="A low-code platform for building applications."
  ["mysql"]="A relational database management system."
  ["outline"]="A knowledge base and wiki platform."
  ["redis"]="An open-source in-memory data structure store."
  ["twentycrm"]="A customer relationship management (CRM) platform."
  ["wuzapi"]="An API management tool for routing and controlling APIs."
  ["appsmith"]="A platform for building internal apps with low code."
  ["documenso"]="A document management system for storing and organizing files."
  ["formbricks"]="A tool for creating and managing forms."
  ["mariadb"]="A relational database management system, a fork of MySQL."
  ["n8n"]="An open-source workflow automation tool."
  ["pgadmin"]="A popular web-based interface for managing PostgreSQL databases."
  ["redisinsight"]="A graphical interface for managing Redis databases."
  ["redis_commander"]="Another graphical interface for managing Redis databases."
  ["typebot"]="A chatbot development platform for building and managing bots."
  ["yourls"]="A URL shortening service."
  ["baserow"]="A no-code platform for building collaborative databases."
  ["docuseal"]="A platform for signing and managing documents."
  ["glpi"]="An IT asset management software."
  ["mattermost"]="An open-source messaging platform for teams."
  ["nextcloud"]="A file-sharing and collaboration platform."
  ["pgvector"]="A PostgreSQL extension for stable with vector data."
  ["stirlingpdf"]="A tool for stable with and managing PDFs."
  ["unoapi"]="An API management platform."
  ["zep"]="A project management and collaboration tool."
  ["botpress"]="An open-source platform for building chatbots."
  ["easyappointments"]="An online scheduling tool for booking appointments."
  ["humhub"]="A social netstable platform for creating and managing communities."
  ["mautic"]="An open-source marketing automation platform."
  ["mosquitto"]="An open-source message broker for handling MQTT messages."
  ["nodered"]="An open-source low-code platform for building IoT applications."
  ["nocobase"]="A no-code platform for building business applications."
  ["phpadmin"]="A web-based interface for managing MySQL and MariaDB databases."
  ["strapi"]="An open-source headless CMS for content management."
  ["uptimekuma"]="An open-source status monitoring tool for websites and services."
  ["calcom"]="A scheduling platform for booking appointments."
  ["evolution"]="A CRM and sales platform."
  ["iceberg"]="A high-performance table format for large analytical datasets."
  ["metabase"]="An open-source business intelligence platform."
  ["nocodb"]="An open-source no-code platform for building applications."
  ["supabase"]="An open-source alternative to Firebase for building backend services."
  ["vaultwarden"]="A self-hosted password manager."
  ["chatwoot"]="An open-source customer support and engagement platform."
  ["evolution_lite"]="A lightweight version of the Evolution CRM platform."
  ["streaming"]="An assemble of Zookeeper, Kafka and Flink." 
  ["minio"]="An open-source object storage service compatible with Amazon S3."
  ["ntfy"]="A simple notification service for sending and receiving messages."
  ["postgres"]="An open-source relational database management system."
  ["tooljet"]="An open-source low-code platform for building internal tools."
  ["weaviate"]="A tool for automating website scraping and analysis."
  ["chatwoot_nestor"]="An extension of the Chatwoot platform for advanced features."
  ["excalidraw"]="A virtual whiteboard for collaborative drawing."
  ["krayincrm"]="A CRM platform for managing customer relationships."
  ["mongodb"]="An open-source NoSQL document database."
  ["odoo"]="An open-source ERP and business management platform."
  ["qdrant"]="A vector database for machine learning and AI applications."
  ["traccar"]="A GPS tracking platform for managing vehicle or asset location."
  ["whoami"]="A simple identity service for determining the current user."
)

# New array for categorizing tools as "stable" or "development"
declare -A stack_status=(
  ["affine"]="stable"
  ["clickhouse"]="stable"
  ["elk"]="beta"
  ["delta_lake"]="beta"
  ["airflow"]="beta"
  ["firecrawl"]="beta"
  ["langflow"]="beta"
  ["jupyter_spark"]="stable"
  ["monitor"]="beta"
  ["ollama"]="stable"
  ["quepasa"]="stable"
  ["woofed"]="beta"
  ["dify"]="beta"
  ["flowise"]="stable"
  ["langfuse"]="beta"
  ["moodle"]="beta"
  ["openproject"]="stable"
  ["rabbitmq"]="stable"
  ["transcrevezap"]="stable"
  ["wordpress"]="beta"
  ["anythingllm"]="beta"
  ["directus"]="beta"
  ["focalboard"]="stable"
  ["lowcoder"]="beta"
  ["mysql"]="stable"
  ["chromadb"]="beta"
  ["outline"]="beta"
  ["redis"]="stable"
  ["twentycrm"]="beta"
  ["wuzapi"]="stable"
  ["appsmith"]="stable"
  ["documenso"]="beta"
  ["formbricks"]="stable"
  ["mariadb"]="stable"
  ["mosquitto"]="beta"  
  ["nodered"]="stable"
  ["n8n"]="stable"
  ["pgadmin"]="stable"
  ["redisinsight"]="stable"
  ["redis_commander"]="beta"
  ["typebot"]="beta"
  ["yourls"]="beta"
  ["baserow"]="beta"
  ["docuseal"]="stable"
  ["glpi"]="stable"
  ["mattermost"]="stable"
  ["nextcloud"]="stable"
  ["pgvector"]="stable"
  ["stirlingpdf"]="stable"
  ["unoapi"]="beta"
  ["zep"]="beta"
  ["botpress"]="stable"
  ["easyappointments"]="beta"
  ["humhub"]="stable"
  ["mautic"]="beta"
  ["nocobase"]="stable"
  ["phpadmin"]="beta"
  ["strapi"]="beta"
  ["uptimekuma"]="stable"
  ["calcom"]="stable"
  ["evolution"]="stable"
  ["iceberg"]="beta"
  ["metabase"]="stable"
  ["nocodb"]="stable"
  ["supabase"]="development"
  ["vaultwarden"]="stable"
  ["chatwoot"]="beta"
  ["chatwoot_nestor"]="beta"
  ["evolution_lite"]="stable"
  ["streaming"]="beta"
  ["minio"]="beta"
  ["ntfy"]="stable"
  ["postgres"]="stable"
  ["tooljet"]="beta"
  ["weaviate"]="beta"
  ["excalidraw"]="stable"
  ["krayincrm"]="beta"
  ["mongodb"]="stable"
  ["odoo"]="stable"
  ["qdrant"]="stable"
  ["traccar"]="beta"
  ["whoami"]="stable"
)
