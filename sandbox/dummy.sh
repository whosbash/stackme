#!/bin/bash
# This script demonstrates grouping a JSON array by a property and iterating over each group.

# Define a sample JSON array
json='[
  {
    "stack_name": "baserow",
    "stack_label": "baserow",
    "stack_description": "A no-code platform for building collaborative databases.",
    "stack_status": "working",
    "category_name": "data_storage",
    "category_label": "Data Storage",
    "category_description": "Tools for managing and storing data, from databases to storage services."
  },
  {
    "stack_name": "flowise",
    "stack_label": "flowise",
    "stack_description": "A low-code platform for automating workflows.",
    "stack_status": "WIP",
    "category_name": "automation_and_low-code",
    "category_label": "Automation and Low-Code",
    "category_description": "Automation and low-code platforms for developing applications quickly."
  },
  {
    "stack_name": "stirlingpdf",
    "stack_label": "stirlingpdf",
    "stack_description": "A tool for working with and managing PDFs.",
    "stack_status": "WIP",
    "category_name": "content_management",
    "category_label": "Content Management",
    "category_description": "Tools for managing documents and content in an organization."
  },
  {
    "stack_name": "redisinsight",
    "stack_label": "redisinsight",
    "stack_description": "A graphical interface for managing Redis databases.",
    "stack_status": "WIP",
    "category_name": "data_storage",
    "category_label": "Data Storage",
    "category_description": "Tools for managing and storing data, from databases to storage services."
  },
  {
    "stack_name": "iceberg",
    "stack_label": "iceberg",
    "stack_description": "A high-performance table format for large analytical datasets.",
    "stack_status": "WIP",
    "category_name": "data_storage",
    "category_label": "Data Storage",
    "category_description": "Tools for managing and storing data, from databases to storage services."
  },
  {
    "stack_name": "clickhouse",
    "stack_label": "clickhouse",
    "stack_description": "A columnar database for online analytical processing (OLAP).",
    "stack_status": "WIP",
    "category_name": "data_storage",
    "category_label": "Data Storage",
    "category_description": "Tools for managing and storing data, from databases to storage services."
  },
  {
    "stack_name": "rabbitmq",
    "stack_label": "rabbitmq",
    "stack_description": "An open-source message broker for handling queues.",
    "stack_status": "working",
    "category_name": "communication",
    "category_label": "Communication",
    "category_description": "Tools for messaging, communication, and collaboration."
  },
  {
    "stack_name": "typebot",
    "stack_label": "typebot",
    "stack_description": "A chatbot development platform for building and managing bots.",
    "stack_status": "WIP",
    "category_name": "communication",
    "category_label": "Communication",
    "category_description": "Tools for messaging, communication, and collaboration."
  },
  {
    "stack_name": "transcrevezap",
    "stack_label": "transcrevezap",
    "stack_description": "A tool for managing WhatsApp message automation.",
    "stack_status": "WIP",
    "category_name": "communication",
    "category_label": "Communication",
    "category_description": "Tools for messaging, communication, and collaboration."
  },
  {
    "stack_name": "docuseal",
    "stack_label": "docuseal",
    "stack_description": "A platform for signing and managing documents.",
    "stack_status": "WIP",
    "category_name": "content_management",
    "category_label": "Content Management",
    "category_description": "Tools for managing documents and content in an organization."
  },
  {
    "stack_name": "pgvector",
    "stack_label": "pgvector",
    "stack_description": "A PostgreSQL extension for working with vector data.",
    "stack_status": "working",
    "category_name": "data_storage",
    "category_label": "Data Storage",
    "category_description": "Tools for managing and storing data, from databases to storage services."
  },
  {
    "stack_name": "vaultwarden",
    "stack_label": "vaultwarden",
    "stack_description": "A self-hosted password manager.",
    "stack_status": "WIP",
    "category_name": "infrastructure",
    "category_label": "Infrastructure",
    "category_description": "Tools related to managing infrastructure and services, including monitoring, security, and more."
  },
  {
    "stack_name": "easyappointments",
    "stack_label": "easyappointments",
    "stack_description": "An online scheduling tool for booking appointments.",
    "stack_status": "WIP",
    "category_name": "scheduling_and_collaboration",
    "category_label": "Scheduling and Collaboration",
    "category_description": "Tools for scheduling and team collaboration."
  },
  {
    "stack_name": "documenso",
    "stack_label": "documenso",
    "stack_description": "A document management system for storing and organizing files.",
    "stack_status": "WIP",
    "category_name": "content_management",
    "category_label": "Content Management",
    "category_description": "Tools for managing documents and content in an organization."
  },
  {
    "stack_name": "n8n",
    "stack_label": "n8n",
    "stack_description": "An open-source workflow automation tool.",
    "stack_status": "WIP",
    "category_name": "automation_and_low-code",
    "category_label": "Automation and Low-Code",
    "category_description": "Automation and low-code platforms for developing applications quickly."
  },
  {
    "stack_name": "mongodb",
    "stack_label": "mongodb",
    "stack_description": "An open-source NoSQL document database.",
    "stack_status": "working",
    "category_name": "data_storage",
    "category_label": "Data Storage",
    "category_description": "Tools for managing and storing data, from databases to storage services."
  },
  {
    "stack_name": "formbricks",
    "stack_label": "formbricks",
    "stack_description": "A tool for creating and managing forms.",
    "stack_status": "working",
    "category_name": "content_management",
    "category_label": "Content Management",
    "category_description": "Tools for managing documents and content in an organization."
  },
  {
    "stack_name": "traefik",
    "stack_label": "traefik",
    "stack_description": "A modern reverse proxy and load balancer.",
    "stack_status": "working",
    "category_name": "infrastructure",
    "category_label": "Infrastructure",
    "category_description": "Tools related to managing infrastructure and services, including monitoring, security, and more."
  },
  {
    "stack_name": "openproject",
    "stack_label": "openproject",
    "stack_description": "A project management tool for collaboration and tracking.",
    "stack_status": "WIP",
    "category_name": "project_management",
    "category_label": "Project Management",
    "category_description": "Tools for managing projects, tasks, and team collaboration."
  },
  {
    "stack_name": "directus",
    "stack_label": "directus",
    "stack_description": "An open-source headless CMS for managing content.",
    "stack_status": "WIP",
    "category_name": "web_development",
    "category_label": "Web Development",
    "category_description": "Tools for building and managing websites and web applications."
  },
  {
    "stack_name": "tooljet",
    "stack_label": "tooljet",
    "stack_description": "An open-source low-code platform for building internal tools.",
    "stack_status": "WIP",
    "category_name": "automation_and_low-code",
    "category_label": "Automation and Low-Code",
    "category_description": "Automation and low-code platforms for developing applications quickly."
  },
  {
    "stack_name": "ollama",
    "stack_label": "ollama",
    "stack_description": "A platform for deploying AI models with ease.",
    "stack_status": "WIP",
    "category_name": "ai",
    "category_label": "AI",
    "category_description": "AI and Natural Language Processing tools to build and deploy models."
  },
  {
    "stack_name": "appsmith",
    "stack_label": "appsmith",
    "stack_description": "A platform for building internal apps with low code.",
    "stack_status": "working",
    "category_name": "automation_and_low-code",
    "category_label": "Automation and Low-Code",
    "category_description": "Automation and low-code platforms for developing applications quickly."
  },
  {
    "stack_name": "affine",
    "stack_label": "affine",
    "stack_description": "A data science tool for building machine learning models.",
    "stack_status": "WIP",
    "category_name": "ai",
    "category_label": "AI",
    "category_description": "AI and Natural Language Processing tools to build and deploy models."
  },
  {
    "stack_name": "zep",
    "stack_label": "zep",
    "stack_description": "A project management and collaboration tool.",
    "stack_status": "working",
    "category_name": "project_management",
    "category_label": "Project Management",
    "category_description": "Tools for managing projects, tasks, and team collaboration."
  },
  {
    "stack_name": "uptimekuma",
    "stack_label": "uptimekuma",
    "stack_description": "An open-source status monitoring tool for websites and services.",
    "stack_status": "WIP",
    "category_name": "infrastructure",
    "category_label": "Infrastructure",
    "category_description": "Tools related to managing infrastructure and services, including monitoring, security, and more."
  },
  {
    "stack_name": "kafka",
    "stack_label": "kafka",
    "stack_description": "A distributed streaming platform for handling real-time data feeds.",
    "stack_status": "WIP",
    "category_name": "communication",
    "category_label": "Communication",
    "category_description": "Tools for messaging, communication, and collaboration."
  },
  {
    "stack_name": "excalidraw",
    "stack_label": "excalidraw",
    "stack_description": "A virtual whiteboard for collaborative drawing.",
    "stack_status": "working",
    "category_name": "design_and_prototyping",
    "category_label": "Design and Prototyping",
    "category_description": "Design and prototyping tools for visualizing ideas."
  },
  {
    "stack_name": "dify",
    "stack_label": "dify",
    "stack_description": "A platform for automating and managing workflows.",
    "stack_status": "WIP",
    "category_name": "automation_and_low-code",
    "category_label": "Automation and Low-Code",
    "category_description": "Automation and low-code platforms for developing applications quickly."
  },
  {
    "stack_name": "evolution_lite",
    "stack_label": "evolution lite",
    "stack_description": "A lightweight version of the Evolution CRM platform.",
    "stack_status": "WIP",
    "category_name": "project_management",
    "category_label": "Project Management",
    "category_description": "Tools for managing projects, tasks, and team collaboration."
  },
  {
    "stack_name": "phpadmin",
    "stack_label": "phpadmin",
    "stack_description": "A web-based interface for managing MySQL and MariaDB databases.",
    "stack_status": "WIP",
    "category_name": "data_management",
    "category_label": "Data Management",
    "category_description": "Tools for managing and administrating databases."
  },
  {
    "stack_name": "nocodb",
    "stack_label": "nocodb",
    "stack_description": "An open-source no-code platform for building applications.",
    "stack_status": "WIP",
    "category_name": "automation_and_low-code",
    "category_label": "Automation and Low-Code",
    "category_description": "Automation and low-code platforms for developing applications quickly."
  },
  {
    "stack_name": "anythingllm",
    "stack_label": "anythingllm",
    "stack_description": "A platform for working with large language models.",
    "stack_status": "WIP",
    "category_name": "ai",
    "category_label": "AI",
    "category_description": "AI and Natural Language Processing tools to build and deploy models."
  },
  {
    "stack_name": "pgadmin",
    "stack_label": "pgadmin",
    "stack_description": "A popular web-based interface for managing PostgreSQL databases.",
    "stack_status": "working",
    "category_name": "data_management",
    "category_label": "Data Management",
    "category_description": "Tools for managing and administrating databases."
  },
  {
    "stack_name": "firecrawl",
    "stack_label": "firecrawl",
    "stack_description": "A web scraping tool for crawling and extracting data from websites.",
    "stack_status": "WIP",
    "category_name": "automation_and_low-code",
    "category_label": "Automation and Low-Code",
    "category_description": "Automation and low-code platforms for developing applications quickly."
  },
  {
    "stack_name": "krayincrm",
    "stack_label": "krayincrm",
    "stack_description": "A CRM platform for managing customer relationships.",
    "stack_status": "WIP",
    "category_name": "project_management",
    "category_label": "Project Management",
    "category_description": "Tools for managing projects, tasks, and team collaboration."
  },
  {
    "stack_name": "humhub",
    "stack_label": "humhub",
    "stack_description": "A social networking platform for creating and managing communities.",
    "stack_status": "WIP",
    "category_name": "social_and_marketing",
    "category_label": "Social and Marketing",
    "category_description": "Social media management and marketing automation tools."
  },
  {
    "stack_name": "redis",
    "stack_label": "redis",
    "stack_description": "An open-source in-memory data structure store.",
    "stack_status": "working",
    "category_name": "data_storage",
    "category_label": "Data Storage",
    "category_description": "Tools for managing and storing data, from databases to storage services."
  },
  {
    "stack_name": "mattermost",
    "stack_label": "mattermost",
    "stack_description": "An open-source messaging platform for teams.",
    "stack_status": "working",
    "category_name": "communication",
    "category_label": "Communication",
    "category_description": "Tools for messaging, communication, and collaboration."
  },
  {
    "stack_name": "mautic",
    "stack_label": "mautic",
    "stack_description": "An open-source marketing automation platform.",
    "stack_status": "WIP",
    "category_name": "social_and_marketing",
    "category_label": "Social and Marketing",
    "category_description": "Social media management and marketing automation tools."
  },
  {
    "stack_name": "unoapi",
    "stack_label": "unoapi",
    "stack_description": "An API management platform.",
    "stack_status": "WIP",
    "category_name": "infrastructure",
    "category_label": "Infrastructure",
    "category_description": "Tools related to managing infrastructure and services, including monitoring, security, and more."
  },
  {
    "stack_name": "postgres",
    "stack_label": "postgres",
    "stack_description": "An open-source relational database management system.",
    "stack_status": "working",
    "category_name": "data_storage",
    "category_label": "Data Storage",
    "category_description": "Tools for managing and storing data, from databases to storage services."
  },
  {
    "stack_name": "twentycrm",
    "stack_label": "twentycrm",
    "stack_description": "A customer relationship management (CRM) platform.",
    "stack_status": "working",
    "category_name": "project_management",
    "category_label": "Project Management",
    "category_description": "Tools for managing projects, tasks, and team collaboration."
  },
  {
    "stack_name": "strapi",
    "stack_label": "strapi",
    "stack_description": "An open-source headless CMS for content management.",
    "stack_status": "working",
    "category_name": "web_development",
    "category_label": "Web Development",
    "category_description": "Tools for building and managing websites and web applications."
  },
  {
    "stack_name": "focalboard",
    "stack_label": "focalboard",
    "stack_description": "A task and project management tool.",
    "stack_status": "WIP",
    "category_name": "project_management",
    "category_label": "Project Management",
    "category_description": "Tools for managing projects, tasks, and team collaboration."
  },
  {
    "stack_name": "calcom",
    "stack_label": "calcom",
    "stack_description": "A scheduling platform for booking appointments.",
    "stack_status": "WIP",
    "category_name": "scheduling_and_collaboration",
    "category_label": "Scheduling and Collaboration",
    "category_description": "Tools for scheduling and team collaboration."
  },
  {
    "stack_name": "mariadb",
    "stack_label": "mariadb",
    "stack_description": "A relational database management system, a fork of MySQL.",
    "stack_status": "working",
    "category_name": "data_storage",
    "category_label": "Data Storage",
    "category_description": "Tools for managing and storing data, from databases to storage services."
  },
  {
    "stack_name": "woofed",
    "stack_label": "woofed",
    "stack_description": "A machine learning framework or platform for model training.",
    "stack_status": "WIP",
    "category_name": "ai",
    "category_label": "AI",
    "category_description": "AI and Natural Language Processing tools to build and deploy models."
  },
  {
    "stack_name": "qdrant",
    "stack_label": "qdrant",
    "stack_description": "A vector database for machine learning and AI applications.",
    "stack_status": "WIP",
    "category_name": "ai",
    "category_label": "AI",
    "category_description": "AI and Natural Language Processing tools to build and deploy models."
  },
  {
    "stack_name": "supabase",
    "stack_label": "supabase",
    "stack_description": "An open-source alternative to Firebase for building backend services.",
    "stack_status": "WIP",
    "category_name": "data_storage",
    "category_label": "Data Storage",
    "category_description": "Tools for managing and storing data, from databases to storage services."
  },
  {
    "stack_name": "botpress",
    "stack_label": "botpress",
    "stack_description": "An open-source platform for building chatbots.",
    "stack_status": "WIP",
    "category_name": "communication",
    "category_label": "Communication",
    "category_description": "Tools for messaging, communication, and collaboration."
  },
  {
    "stack_name": "quepasa",
    "stack_label": "quepasa",
    "stack_description": "A chatbot and customer support tool for automating conversations.",
    "stack_status": "WIP",
    "category_name": "communication",
    "category_label": "Communication",
    "category_description": "Tools for messaging, communication, and collaboration."
  },
  {
    "stack_name": "evolution",
    "stack_label": "evolution",
    "stack_description": "A CRM and sales platform.",
    "stack_status": "working",
    "category_name": "project_management",
    "category_label": "Project Management",
    "category_description": "Tools for managing projects, tasks, and team collaboration."
  },
  {
    "stack_name": "nocobase",
    "stack_label": "nocobase",
    "stack_description": "A no-code platform for building business applications.",
    "stack_status": "WIP",
    "category_name": "automation_and_low-code",
    "category_label": "Automation and Low-Code",
    "category_description": "Automation and low-code platforms for developing applications quickly."
  },
  {
    "stack_name": "portainer",
    "stack_label": "portainer",
    "stack_description": "A tool for managing Docker containers.",
    "stack_status": "working",
    "category_name": "infrastructure",
    "category_label": "Infrastructure",
    "category_description": "Tools related to managing infrastructure and services, including monitoring, security, and more."
  },
  {
    "stack_name": "langfuse",
    "stack_label": "langfuse",
    "stack_description": "A platform for integrating large language models into workflows.",
    "stack_status": "WIP",
    "category_name": "ai",
    "category_label": "AI",
    "category_description": "AI and Natural Language Processing tools to build and deploy models."
  },
  {
    "stack_name": "weavite",
    "stack_label": "weavite",
    "stack_description": "A tool for automating website scraping and analysis.",
    "stack_status": "WIP",
    "category_name": "automation_and_low-code",
    "category_label": "Automation and Low-Code",
    "category_description": "Automation and low-code platforms for developing applications quickly."
  },
  {
    "stack_name": "metabase",
    "stack_label": "metabase",
    "stack_description": "An open-source business intelligence platform.",
    "stack_status": "WIP",
    "category_name": "analytics",
    "category_label": "Analytics",
    "category_description": "Business Intelligence and analytics tools for data analysis and reporting."
  },
  {
    "stack_name": "nextcloud",
    "stack_label": "nextcloud",
    "stack_description": "A file-sharing and collaboration platform.",
    "stack_status": "WIP",
    "category_name": "scheduling_and_collaboration",
    "category_label": "Scheduling and Collaboration",
    "category_description": "Tools for scheduling and team collaboration."
  },
  {
    "stack_name": "ntfy",
    "stack_label": "ntfy",
    "stack_description": "A simple notification service for sending and receiving messages.",
    "stack_status": "WIP",
    "category_name": "communication",
    "category_label": "Communication",
    "category_description": "Tools for messaging, communication, and collaboration."
  },
  {
    "stack_name": "airflow",
    "stack_label": "airflow",
    "stack_description": "An open-source workflow automation platform.",
    "stack_status": "WIP",
    "category_name": "automation_and_low-code",
    "category_label": "Automation and Low-Code",
    "category_description": "Automation and low-code platforms for developing applications quickly."
  },
  {
    "stack_name": "chatwoot",
    "stack_label": "chatwoot",
    "stack_description": "An open-source customer support and engagement platform.",
    "stack_status": "WIP",
    "category_name": "communication",
    "category_label": "Communication",
    "category_description": "Tools for messaging, communication, and collaboration."
  },
  {
    "stack_name": "whoami",
    "stack_label": "whoami",
    "stack_description": "A simple identity service for determining the current user.",
    "stack_status": "WIP",
    "category_name": "miscellaneous",
    "category_label": "Miscellaneous",
    "category_description": "Other useful or unique tools."
  },
  {
    "stack_name": "lowcoder",
    "stack_label": "lowcoder",
    "stack_description": "A low-code platform for building applications.",
    "stack_status": "WIP",
    "category_name": "automation_and_low-code",
    "category_label": "Automation and Low-Code",
    "category_description": "Automation and low-code platforms for developing applications quickly."
  },
  {
    "stack_name": "wordpress",
    "stack_label": "wordpress",
    "stack_description": "A popular content management system (CMS) for building websites.",
    "stack_status": "WIP",
    "category_name": "web_development",
    "category_label": "Web Development",
    "category_description": "Tools for building and managing websites and web applications."
  },
  {
    "stack_name": "langflow",
    "stack_label": "langflow",
    "stack_description": "An AI tool for managing workflows for large language models (LLMs).",
    "stack_status": "WIP",
    "category_name": "ai",
    "category_label": "AI",
    "category_description": "AI and Natural Language Processing tools to build and deploy models."
  },
  {
    "stack_name": "glpi",
    "stack_label": "glpi",
    "stack_description": "An IT asset management software.",
    "stack_status": "WIP",
    "category_name": "infrastructure",
    "category_label": "Infrastructure",
    "category_description": "Tools related to managing infrastructure and services, including monitoring, security, and more."
  },
  {
    "stack_name": "chatwoot_nestor",
    "stack_label": "chatwoot nestor",
    "stack_description": "An extension of the Chatwoot platform for advanced features.",
    "stack_status": "WIP",
    "category_name": "communication",
    "category_label": "Communication",
    "category_description": "Tools for messaging, communication, and collaboration."
  },
  {
    "stack_name": "odoo",
    "stack_label": "odoo",
    "stack_description": "An open-source ERP and business management platform.",
    "stack_status": "WIP",
    "category_name": "erp",
    "category_label": "ERP",
    "category_description": "Enterprise Resource Planning and other solutions for managing business operations."
  },
  {
    "stack_name": "outline",
    "stack_label": "outline",
    "stack_description": "A knowledge base and wiki platform.",
    "stack_status": "WIP",
    "category_name": "content_management",
    "category_label": "Content Management",
    "category_description": "Tools for managing documents and content in an organization."
  },
  {
    "stack_name": "mysql",
    "stack_label": "mysql",
    "stack_description": "A relational database management system.",
    "stack_status": "working",
    "category_name": "data_storage",
    "category_label": "Data Storage",
    "category_description": "Tools for managing and storing data, from databases to storage services."
  },
  {
    "stack_name": "minio",
    "stack_label": "minio",
    "stack_description": "An open-source object storage service compatible with Amazon S3.",
    "stack_status": "WIP",
    "category_name": "data_storage",
    "category_label": "Data Storage",
    "category_description": "Tools for managing and storing data, from databases to storage services."
  },
  {
    "stack_name": "wuzapi",
    "stack_label": "wuzapi",
    "stack_description": "An API management tool for routing and controlling APIs.",
    "stack_status": "WIP",
    "category_name": "infrastructure",
    "category_label": "Infrastructure",
    "category_description": "Tools related to managing infrastructure and services, including monitoring, security, and more."
  },
  {
    "stack_name": "yourls",
    "stack_label": "yourls",
    "stack_description": "A URL shortening service.",
    "stack_status": "WIP",
    "category_name": "infrastructure",
    "category_label": "Infrastructure",
    "category_description": "Tools related to managing infrastructure and services, including monitoring, security, and more."
  },
  {
    "stack_name": "monitor",
    "stack_label": "monitor",
    "stack_description": "A system monitoring tool for tracking performance and uptime.",
    "stack_status": "WIP",
    "category_name": "infrastructure",
    "category_label": "Infrastructure",
    "category_description": "Tools related to managing infrastructure and services, including monitoring, security, and more."
  },
  {
    "stack_name": "traccar",
    "stack_label": "traccar",
    "stack_description": "A GPS tracking platform for managing vehicle or asset location.",
    "stack_status": "working",
    "category_name": "location_services",
    "category_label": "Location Services",
    "category_description": "Tools for location-based services and geospatial data."
  },
  {
    "stack_name": "moodle",
    "stack_label": "moodle",
    "stack_description": "An open-source learning management system (LMS).",
    "stack_status": "WIP",
    "category_name": "content_management",
    "category_label": "Content Management",
    "category_description": "Tools for managing documents and content in an organization."
  }
]'

# Group the JSON objects by the "group" property.
# This returns an array of groups (each group is an array of objects)
groups="$(echo "$json" | jq -c 'group_by(.category_name)')"

echo "Grouped JSON:"
echo "$groups"
echo

# Iterate over each group.
# 'jq -c ".[]"' outputs each group (a JSON array) on a separate line.
echo "Iterating over each group:"
while IFS= read -r group; do
  echo "Group: $group"
  echo "----------------------"
done < <(echo "$groups" | jq -c '.[]')
