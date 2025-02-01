#!/bin/bash

declare -A descriptions=(
  ["affine"]="A data science tool for building machine learning models."
  ["clickhouse"]="A columnar database for online analytical processing (OLAP)."
  ["firecrawl"]="A web scraping tool for crawling and extracting data from websites."
  ["langflow"]="An AI tool for managing workflows for large language models (LLMs)."
  ["monitor"]="A system monitoring tool for tracking performance and uptime."
  ["ollama"]="A platform for deploying AI models with ease."
  ["quepasa"]="A chatbot and customer support tool for automating conversations."
  ["traefik"]="A modern reverse proxy and load balancer."
  ["woofed"]="A machine learning framework or platform for model training."
  ["airflow"]="An open-source workflow automation platform."
  ["dify"]="A platform for automating and managing workflows."
  ["flowise"]="A low-code platform for automating workflows."
  ["langfuse"]="A platform for integrating large language models into workflows."
  ["moodle"]="An open-source learning management system (LMS)."
  ["openproject"]="A project management tool for collaboration and tracking."
  ["rabbitmq"]="An open-source message broker for handling queues."
  ["transcrevezap"]="A tool for managing WhatsApp message automation."
  ["wordpress"]="A popular content management system (CMS) for building websites."
  ["anythingllm"]="A platform for working with large language models."
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
  ["typebot"]="A chatbot development platform for building and managing bots."
  ["yourls"]="A URL shortening service."
  ["baserow"]="A no-code platform for building collaborative databases."
  ["docuseal"]="A platform for signing and managing documents."
  ["glpi"]="An IT asset management software."
  ["mattermost"]="An open-source messaging platform for teams."
  ["nextcloud"]="A file-sharing and collaboration platform."
  ["pgvector"]="A PostgreSQL extension for working with vector data."
  ["stirlingpdf"]="A tool for working with and managing PDFs."
  ["unoapi"]="An API management platform."
  ["zep"]="A project management and collaboration tool."
  ["botpress"]="An open-source platform for building chatbots."
  ["easyappointments"]="An online scheduling tool for booking appointments."
  ["humhub"]="A social networking platform for creating and managing communities."
  ["mautic"]="An open-source marketing automation platform."
  ["nocobase"]="A no-code platform for building business applications."
  ["phpadmin"]="A web-based interface for managing MySQL and MariaDB databases."
  ["strapi"]="An open-source headless CMS for content management."
  ["uptimekuma"]="An open-source status monitoring tool for websites and services."
  ["calcom"]="A scheduling platform for booking appointments."
  ["evolution"]="A CRM and sales platform."
  ["iceberg"]="A high-performance table format for large analytical datasets."
  ["metabase"]="An open-source business intelligence platform."
  ["nocodb"]="An open-source no-code platform for building applications."
  ["portainer"]="A tool for managing Docker containers."
  ["supabase"]="An open-source alternative to Firebase for building backend services."
  ["vaultwarden"]="A self-hosted password manager."
  ["chatwoot"]="An open-source customer support and engagement platform."
  ["evolution_lite"]="A lightweight version of the Evolution CRM platform."
  ["kafka"]="A distributed streaming platform for handling real-time data feeds."
  ["minio"]="An open-source object storage service compatible with Amazon S3."
  ["ntfy"]="A simple notification service for sending and receiving messages."
  ["postgres"]="An open-source relational database management system."
  ["tooljet"]="An open-source low-code platform for building internal tools."
  ["weavite"]="A tool for automating website scraping and analysis."
  ["chatwoot_nestor"]="An extension of the Chatwoot platform for advanced features."
  ["excalidraw"]="A virtual whiteboard for collaborative drawing."
  ["krayincrm"]="A CRM platform for managing customer relationships."
  ["mongodb"]="An open-source NoSQL document database."
  ["odoo"]="An open-source ERP and business management platform."
  ["qdrant"]="A vector database for machine learning and AI applications."
  ["traccar"]="A GPS tracking platform for managing vehicle or asset location."
  ["whoami"]="A simple identity service for determining the current user."
)

declare -A categories
categories=(
  ["Infrastructure & Services"]="monitor uptimekuma glpi traefik vaultwarden wuzapi unoapi yourls portainer"
  ["Data Storage"]="supabase clickhouse redis redisinsight pgvector iceberg minio mysql mariadb baserow postgres mongodb"
  ["Data Management"]="pgadmin phpadmin"
  ["Analytics & BI"]="metabase"
  ["Project & Task Management"]="openproject focalboard zep twentycrm evolution evolution_lite krayincrm"
  ["ERP & Enterprise Solutions"]="odoo"
  ["AI & NLP"]="affine ollama anythingllm qdrant woofed langflow langfuse"
  ["Messaging & Communication"]="rabbitmq transcrevezap kafka quepasa typebot botpress chatwoot chatwoot_nestor mattermost ntfy"
  ["Document & Content Management"]="documenso docuseal stirlingpdf formbricks moodle outline"
  ["Web Development"]="wordpress directus strapi"
  ["Automation & Low-Code"]="firecrawl weavite n8n dify airflow flowise lowcoder appsmith nocobase nocodb tooljet"
  ["Scheduling & Collaboration"]="easyappointments calcom nextcloud"
  ["Social & Marketing"]="humhub mautic"
  ["Location Services"]="traccar"
  ["Design & Prototyping"]="excalidraw"
  ["Miscellaneous"]="whoami"
)

# New array for categorizing tools as "working" or "WIP"
declare -A tool_status=(
  ["affine"]="WIP"
  ["clickhouse"]="WIP"
  ["firecrawl"]="WIP"
  ["langflow"]="WIP"
  ["monitor"]="WIP"
  ["ollama"]="WIP"
  ["quepasa"]="WIP"
  ["traefik"]="working"
  ["woofed"]="WIP"
  ["airflow"]="WIP"
  ["dify"]="WIP"
  ["flowise"]="WIP"
  ["langfuse"]="WIP"
  ["moodle"]="WIP"
  ["openproject"]="WIP"
  ["rabbitmq"]="working"
  ["transcrevezap"]="WIP"
  ["wordpress"]="WIP"
  ["anythingllm"]="WIP"
  ["directus"]="WIP"
  ["focalboard"]="WIP"
  ["lowcoder"]="WIP"
  ["mysql"]="working"
  ["outline"]="WIP"
  ["redis"]="working"
  ["twentycrm"]="working"
  ["wuzapi"]="WIP"
  ["appsmith"]="working"
  ["documenso"]="WIP"
  ["formbricks"]="working"
  ["mariadb"]="working"
  ["n8n"]="WIP"
  ["pgadmin"]="working"
  ["redisinsight"]="WIP"
  ["typebot"]="WIP"
  ["yourls"]="WIP"
  ["baserow"]="working"
  ["docuseal"]="WIP"
  ["glpi"]="WIP"
  ["mattermost"]="working"
  ["nextcloud"]="WIP"
  ["pgvector"]="working"
  ["stirlingpdf"]="WIP"
  ["unoapi"]="WIP"
  ["zep"]="working"
  ["botpress"]="WIP"
  ["easyappointments"]="WIP"
  ["humhub"]="WIP"
  ["mautic"]="WIP"
  ["nocobase"]="WIP"
  ["phpadmin"]="WIP"
  ["strapi"]="working"
  ["uptimekuma"]="WIP"
  ["calcom"]="WIP"
  ["evolution"]="working"
  ["iceberg"]="WIP"
  ["metabase"]="WIP"
  ["nocodb"]="WIP"
  ["portainer"]="working"
  ["supabase"]="WIP"
  ["vaultwarden"]="WIP"
  ["chatwoot"]="WIP"
  ["evolution_lite"]="WIP"
  ["kafka"]="WIP"
  ["minio"]="WIP"
  ["ntfy"]="WIP"
  ["postgres"]="working"
  ["tooljet"]="WIP"
  ["weavite"]="WIP"
  ["chatwoot_nestor"]="WIP"
  ["excalidraw"]="working"
  ["krayincrm"]="WIP"
  ["mongodb"]="working"
  ["odoo"]="WIP"
  ["qdrant"]="WIP"
  ["traccar"]="working"
  ["whoami"]="WIP"
)

build_stack_objects(){
    # Initialize an empty JSON array
    json_output="[]"

    # Iterate over each tool
    for name in "${!descriptions[@]}"; do
        desc="${descriptions[$name]}"
        category="Unknown"
        status="${tool_status[$name]:-Unknown}"  # Get status from the tool_status array (assumed to be populated)

        # Find the category for the current tool
        for cat in "${!categories[@]}"; do
            if [[ " ${categories[$cat]} " =~ " $name " ]]; then
                category="$cat"
                break
            fi
        done

        # Lowercase transformation functions for labels
        lowercase_transform() {
            echo "$1" | tr '[:upper:]' '[:lower:]' | tr -s ' ' '_'
        }

        # Create transformed labels
        category_name=$(lowercase_transform "$category")
        category_label="${category//_/ }"  # Convert underscores to spaces
        stack_name=$(lowercase_transform "$name")
        stack_label="${name//_/ }"  # Convert underscores to spaces

        stack_item=$(jq -n \
            --arg category_name "$category_name" \
            --arg category_label "$category_label" \
            --arg stack_name "$stack_name" \
            --arg stack_label "$stack_label" \
            --arg desc "$desc" \
            --arg status "$status" \
            '{
                "category_name": $category_name,
                "category_label": $category_label,
                "stack_name": $stack_name,
                "stack_label": $stack_label,
                "stack_description": $desc,
                "status": $status
            }')

        # Append the stack_item to the JSON array
        json_output=$(jq -c ". + [$stack_item]" <<< "$json_output")
    done

    # Output the final JSON array
    echo "$json_output"
}

# Output the final JSON array with status
time build_stack_objects | jq '.'