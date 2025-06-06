FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV ANSIBLE_GATHERING=smart
ENV ANSIBLE_STDOUT_CALLBACK=yaml

# Install system dependencies (these rarely change)
RUN apt-get update && apt-get install -y \
    git \
    openssh-client \
    sshpass \
    rsync \
    curl \
    wget \
    vim \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Create ansible user and directory (stable layer)
RUN useradd -m -s /bin/bash ansible
WORKDIR /ansible

# Copy requirements.txt first (for better caching)
COPY requirements.txt .

# Install Python dependencies (only rebuilds when requirements.txt changes)
RUN pip install --no-cache-dir -r requirements.txt

# Create SSH directory with proper permissions (stable layer)
RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh

# Create ansible directories (stable layer)
RUN mkdir -p /ansible/{inventory,playbooks,roles,group_vars,host_vars}

# Set proper ownership (stable layer)
RUN chown -R ansible:ansible /ansible

# Switch to ansible user
USER ansible

# Set working directory
WORKDIR /ansible

# Default command
CMD ["/bin/bash"] 