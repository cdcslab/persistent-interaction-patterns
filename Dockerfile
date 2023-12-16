
FROM rocker/rstudio:4.3

WORKDIR /app

RUN apt-get update && apt-get install -y \
    libpq-dev \
    cmake \
    libz-dev \ 
    libpng-dev

RUN Rscript -e "install.packages('remotes', repos = c(CRAN = 'https://cloud.r-project.org'))"
RUN Rscript -e "remotes::install_github('rstudio/renv')"

COPY renv.lock renv.lock

RUN Rscript -e 'renv::restore()'

RUN mkdir -p /home/rstudio/.cache/
RUN sudo chown -R rstudio /home/rstudio/.cache/

COPY . /app

# Run scripts
RUN Rscript -e 'renv::run("/app/src/analysis/main/figures/figure_1/create_data_distributions.R")'
RUN Rscript -e 'renv::run("/app/src/transformation/create_toxicity_percentage_by_binned_conversation_size_and_with_bin_ge_07.R")'
RUN Rscript -e 'renv::run("/app/src/analysis/main/figures/figure_1/create_data_participation_vs_bin.R")'
RUN Rscript -e 'renv::run("/app/src/visualization/figure_1/plot_figure_1.R")'
RUN Rscript -e 'renv::run("/app/src/transformation/figure_2/create_data_toxicity_percentage_by_bin.R")'
RUN Rscript -e 'renv::run("/app/src/visualization/figure_2/plot_figure_2.R")'
RUN Rscript -e 'renv::run("/app/src/analysis/main/figures/figure_3/create_data_correlation_toxicity_and_participation.R")'
RUN Rscript -e 'renv::run("/app/src/analysis/main/figures/figure_3/create_data_differences_between_toxic_and_non_toxic_threads.R")'
RUN Rscript -e 'renv::run("/app/src/visualization/figure_3/plot_figure_3.R")'
RUN Rscript -e 'renv::run("/app/src/analysis/main/figures/figure_4/4b_upvotes_vs_toxicity/create_data_likes_vs_toxicity.R")'
RUN Rscript -e 'renv::run("/app/src/visualization/figure_4/plot_figure_4.R")'
RUN Rscript -e 'renv::run("/app/src/analysis/main/tables/table_1/create_table_1.R")'
RUN Rscript -e 'renv::run("/app/src/analysis/ED/figures/extended_data_figure_1/create_data_user_lifetime_distribution.R")'
RUN Rscript -e 'renv::run("/app/src/analysis/ED/figures/extended_data_figure_1/create_data_thread_size_distribution.R")'
RUN Rscript -e 'renv::run("/app/src/analysis/ED/figures/extended_data_figure_1/create_data_thread_lifetime_distribution.R")'
RUN Rscript -e 'renv::run("/app/src/visualization/extended_data_figure_1/plot_extended_data_figure_1.R")'
RUN Rscript -e 'renv::run("/app/src/analysis/ED/figures/extended_data_figure_2/create_data_toxicity_extremely_toxic_authors.R")'
RUN Rscript -e 'renv::run("/app/src/analysis/ED/figures/extended_data_figure_2/create_data_toxicity_conversation_with_at_least_11_comments.R")'

RUN Rscript -e 'renv::run("/app/src/analysis/ED/figures/extended_data_figure_3/create_data_toxicity_vs_bin.R")'
RUN Rscript -e 'renv::run("/app/src/visualization/extended_data_figure_3/plot_toxicity_vs_bin.R")'

RUN Rscript -e 'renv::run("/app/src/analysis/ED/figures/extended_data_figure_4/create_data_toxicity_vs_lifetime_user.R")'
RUN Rscript -e 'renv::run("/app/src/analysis/ED/figures/extended_data_figure_4/create_data_toxicity_vs_lifetime_threads.R")'
RUN Rscript -e 'renv::run("/app/src/visualization/extended_data_figure_4/plot_extended_figure_4.R")'

RUN Rscript -e 'renv::run("/app/src/analysis/ED/tables/extended_data_table_3/create_ed_table_3.R")'

ENV USER="rstudio"
CMD ["/usr/lib/rstudio-server/bin/rserver", "--server-daemonize", "0", "--auth-none", "1"]