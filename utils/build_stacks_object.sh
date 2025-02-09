#!/bin/bash

declare -A descriptions=(
  ["affine"]="A data science tool for building machine learning models."
  ["clickhouse"]="A columnar database for online analytical processing (OLAP)."
  ["firecrawl"]="A web scraping tool for crawling and extracting data from websites."
  ["langflow"]="An AI tool for managing workflows for large language models (LLMs)."
  ["monitor"]="A system monitoring tool for tracking performance and uptime."
  ["ollama"]="A platform for deploying AI models with ease."
  ["quepasa"]="A chatbot and customer support tool for automating conversations."
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

declare -A categories_to_stacks
categories_to_stacks=(
  ["Infrastructure"]="monitor uptimekuma glpi vaultwarden wuzapi unoapi yourls"
  ["Data Storage"]="supabase clickhouse redis pgvector iceberg minio mysql mariadb baserow postgres mongodb"
  ["IoT"]="mosquitto nodered"
  ["Data Management"]="pgadmin phpadmin redis_commander redisinsight"
  ["Analytics"]="metabase"
  ["Project Management"]="openproject focalboard zep twentycrm evolution evolution_lite krayincrm"
  ["ERP"]="odoo"
  ["AI"]="affine ollama anythingllm qdrant woofed langflow langfuse"
  ["Communication"]="mosquitto rabbitmq transcrevezap kafka quepasa typebot botpress chatwoot chatwoot_nestor mattermost ntfy"
  ["Content Management"]="documenso docuseal stirlingpdf formbricks moodle outline"
  ["Web Development"]="wordpress directus strapi"
  ["Automation and Low-Code"]="firecrawl weavite n8n dify airflow flowise lowcoder appsmith nocobase nocodb tooljet"
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

# New array for categorizing tools as "stable" or "development"
declare -A tool_status=(
  ["affine"]="beta"
  ["clickhouse"]="stable"
  ["firecrawl"]="beta"
  ["langflow"]="beta"
  ["monitor"]="beta"
  ["ollama"]="stable"
  ["quepasa"]="beta"
  ["woofed"]="beta"
  ["airflow"]="beta"
  ["dify"]="beta"
  ["flowise"]="beta"
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
  ["outline"]="beta"
  ["redis"]="stable"
  ["twentycrm"]="stable"
  ["wuzapi"]="beta"
  ["appsmith"]="stable"
  ["documenso"]="beta"
  ["formbricks"]="stable"
  ["mariadb"]="stable"
  ["mosquitto"]="beta"  
  ["nodered"]="stable"
  ["n8n"]="stable"
  ["pgadmin"]="stable"
  ["redisinsight"]="beta"
  ["redis_commander"]="beta"
  ["typebot"]="beta"
  ["yourls"]="beta"
  ["baserow"]="beta"
  ["docuseal"]="beta"
  ["glpi"]="stable"
  ["mattermost"]="stable"
  ["nextcloud"]="beta"
  ["pgvector"]="stable"
  ["stirlingpdf"]="stable"
  ["unoapi"]="beta"
  ["zep"]="stable"
  ["botpress"]="stable"
  ["easyappointments"]="beta"
  ["humhub"]="stable"
  ["mautic"]="beta"
  ["nocobase"]="beta"
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
  ["kafka"]="beta"
  ["minio"]="beta"
  ["ntfy"]="stable"
  ["postgres"]="stable"
  ["tooljet"]="beta"
  ["weavite"]="beta"
  ["excalidraw"]="stable"
  ["krayincrm"]="beta"
  ["mongodb"]="stable"
  ["odoo"]="stable"
  ["qdrant"]="beta"
  ["traccar"]="beta"
  ["whoami"]="stable"
)

build_stack_objects(){
    # Initialize an empty JSON array
    json_output="[]"

    # Iterate over each tool
    for name in "${!descriptions[@]}"; do
        desc="${descriptions[$name]}"  # Tool description
        category="Unknown"
        status="${tool_status[$name]:-Unknown}"  # Get status from the tool_status array (assumed to be populated)

        # Find the category for the current tool
        for cat in "${!categories_to_stacks[@]}"; do
            if [[ " ${categories_to_stacks[$cat]} " =~ " $name " ]]; then
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

        # Fetch the description for the category from the categories_descriptions array
        category_description="${categories_descriptions[$category]:-No description available}"

        # Create the stack object with the category_description
        stack_item=$(jq -n \
            --arg category_name "$category_name" \
            --arg category_label "$category_label" \
            --arg stack_name "$stack_name" \
            --arg stack_label "$stack_label" \
            --arg desc "$desc" \
            --arg category_description "$category_description" \
            --arg status "$status" \
            '{
                "stack_name": $stack_name,
                "stack_label": $stack_label,
                "stack_description": $desc,
                "stack_status": $status,
                "category_name": $category_name,
                "category_label": $category_label,
                "category_description": $category_description,                
            }')

        # Append the stack_item to the JSON array
        json_output=$(jq -c ". + [$stack_item]" <<< "$json_output")
    done

    # Output the final JSON array
    echo "$json_output"
}

generate_stack_status_stats_percentage() {
  local total_count
  total_count=$(printf '%s\n' "${tool_status[@]}" | wc -l)  # Get total number of items

  if [[ "$total_count" -eq 0 ]]; then
    echo '{}'  # Return empty JSON object if no statuses are present
    return
  fi

  printf '%s\n' "${tool_status[@]}" | jq -R . | jq -s --arg total "$total_count" '
    group_by(.) | map({(.[0]): { count: length, percentage: (length * 100 / ($total | tonumber)) }}) | add
    | { development, beta, stable }'  # Force order of keys
}

sort_by_complexity_and_status(){
  local local folder_path="$1"

  # Initialize an empty JSON object
  json_output="{}"

  # Find files, count unique Mustache variables, and categorize
  while IFS= read -r -d '' file; do
      # Extract unique Mustache variables
      mustache_vars=$(grep -o '{{[^}]*}}' "$file" | sed 's/[{}]//g' | sort -u | tr '\n' ' ')
      
      # Count unique Mustache variables
      unique_count=$(echo "$mustache_vars" | wc -w)

      # Extract tool name from filename (assuming format like 'toolname.config' or similar)
      tool_name=$(basename "$file" | cut -d. -f1)

      # Determine category based on tool_status mapping
      category="${tool_status[$tool_name]:-unknown}"

      # Construct JSON entry
      entry="{\"file\": \"$file\", \"complexity\": $unique_count, \"variables\": \"$mustache_vars\"}"

      # Append to JSON object grouped by category
      json_output=$(echo "$json_output" | jq --arg cat "$category" --argjson entry "$entry" '
          .[$cat] += [$entry] // [$entry]
      ')
  done < <(find "$folder_path" -type f -print0)

  # Pretty-print the JSON output and sort by complexity in descending order
  echo "$json_output" | \
  jq 'to_entries | map({key: .key, value: (.value | sort_by(.complexity) | reverse)}) | from_entries'
}


# Output the final JSON array with status
time build_stack_objects | jq '.' > "./stacks/stacks.json"

sort_by_complexity_and_status "$1"

generate_stack_status_stats_percentage