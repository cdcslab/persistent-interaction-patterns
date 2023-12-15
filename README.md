The following repository contains the code for 'Toxicity in Online Conversations' paper.

# How to run

1. Install Docker
2. In the repository folder, create the container by typing the following command in the shell

```
docker-compose up --build -d
```

3. To run the container, type

```
docker-compose up -d
```

The script automatically runs the code to create figures and tables for Voat dataset, which will appear in the figures and data folder respectively.

To inspect the code by using RStudio, type localhost:8787 on your browser to access the RStudio Server installation in the container.
