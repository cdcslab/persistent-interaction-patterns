# System Requirements

The paper code was developed and tested on Ubuntu 20.04.6 LTS, using the following softwares:

- R version 4.3.1 (2023-06-16) -- "Beagle Scouts"
- Python 3.8.10
- RStudio 2021.09.1 Build 372
- Visual Studio Code 1.85.0

# Installation guide

First, install renv library from CRAN:

```
install.packages("renv")
```

Then, initialize the project and collect all the packages
```
renv::init()
```

Create a lockfile with 
```
renv::snapshot()
```

Now, build the docker image with
```
docker-compose up --build -d
```


## Reproducibility Instructions
To reproduce our analysis, we provide Voat as an example dataset, whose comments were previously labeled with Perspective API. It can be found at the [following link](https://osf.io/fq5dy/). .To help the readers understanding the structure of the dataset, we provide a list of its columns with their description:

```
Column              Type              Explanation
comment_id          string            ID of the comment
video_id            string            ID of the video in the comment
created_at          date              Comment creation date
user                string            ID of the user commenting
root_sumbission     string            ID of the post containing the comment
text                int               Text
upvotes             int               Number of upvotes
downvotes           int               Number of downvotes
depth               int               Comment depth in the thread tree
toxicity_score      real              Perspective Toxicity Score
topic               string            Subverse topic
social              string            Social the comment belongs to (Voat)
```

## How to reproduce the analysis    

The project is structured in the following way:
```
├── 
│   ├── data
│       ├── Labeled
│           ├── Voat
│               ├── voat_labeled_data.parquet  
│   ├── src
│   ├── utils
```
To reproduce the work, it is required to place voat_labeled_data.parquet dataset into the data/Labeled/Voat folder.

More specifically, src has the following internal structure:

```
├── analysis/
│   ├── burst_analysis/
│   │   └── get_facebook_news_sample.R
│   ├── ED/
│   │   └── tables/
│   │       ├── extended_table_2/
│   │       │   └── create_ed_table_2.R
│   │       └── extended_table_5/
│   │           └── create_table_ed_5.R
│   ├── main/
│   │   └── tables/
│   │       └── table_1/
│   │           └── create_table_1.R
│   └── turnover_between_bins/
│       ├── create_data_turnover_between_bins.R
│       └── create_data_turnover_between_bins_post.R
├── transformation/
│   ├── create_short_conversation.R
│   ├── create_thresholded_data_ge_07_validation_dataset.R
│   ├── create_toxicity_percentage_by_binned_conversation_size_and_with_bin_ge_07.R
│   ├── extended_data_figure_3/
│   ├── extended_data_figure_4/
│   │   └── fb_news_create_results_for_figure_4a_and_4b.R
│   ├── extended_data_figure_7/
│   │   └── fb_news_create_data_figure_7ED.R
│   ├── extended_data_figure_8/
│   │   └── fb_news_create_data_for_figure_ED8.R
│   ├── extended_table_3/
│   │   └── create_ed_table_3.R
│   ├── fb_news_create_toxicity_percentage_by_binned_conversation_size_and_with_bin_ge_07.R
│   ├── figure_2/
│   │   ├── create_data_toxicity_percentage_by_bin.R
│   │   └── fb_news_create_data_toxicity_percentage_by_bin.R
│   ├── figure_3/
│   │   ├── create_data_correlation_toxicity_and_participation.R
│   │   └── create_data_differences_between_toxic_and_non_toxic_threads.R
│   ├── figure_4/
│   │   ├── 4a_controversy/
│   │   │   ├── facebook/
│   │   │   │   ├── facebook_extract_comments_to_label_for_sentiment_analysis.R
│   │   │   │   ├── fb_create_datasets_for_controversy.R
│   │   │   │   ├── fb_news_extract_controversy_comments.R
│   │   │   │   ├── fb_news_get_likes_per_comment_bin.R
│   │   │   │   ├── fb_news_get_users_with_at_least_three_likes.R
│   │   │   │   └── sentiment-analysis-facebook-news.py
│   │   │   ├── gab/
│   │   │   │   ├── gab_convert_attachment_json_to_object.py
│   │   │   │   ├── gab_create_dataset_for_controversy.R
│   │   │   │   ├── gab_create_dataset_of_comments_with_link.R
│   │   │   │   ├── gab_expand_links.py
│   │   │   │   └── gab_select_links_to_expand.R
│   │   │   ├── to_remove.parquet
│   │   │   └── twitter/
│   │   │       ├── twitter_create_user_post_datasets_for_controversy.R
│   │   │       ├── twitter_expand_links.py
│   │   │       ├── twitter_news_create_dataset.R
│   │   │       ├── twitter_news_create_datasets_for_controversy.R
│   │   │       ├── twitter_unify_expanded_urls_to_vaccine_labeled_dataframe.R
│   │   │       ├── twitter_vaccines_create_datasets_for_controversy.R
│   │   │       ├── twitter_vaccines_expand_urls.R
│   │   │       ├── twitter_vaccines_extract_urls.R
│   │   │       └── twitter_vaccines_extract_urls_from_json.py
│   │   └── 4b_upvotes_vs_toxicity/
│   │       ├── create_data_likes_vs_toxicity.R
│   │       └── fb_news_create_data_likes_vs_toxicity_bin.R
│   ├── save_validation_dataset_with_no_root.R
│   ├── unify_fb_binnings.R
│   ├── unify_linear_binned_thresholded_toxic_non_toxic_comments.R.r
│   └── unify_validation_dataset.R
└── visualization/
    ├── extended_data_figure_1/
    │   └── plot_extended_data_figure_1.R
    ├── extended_data_figure_2/
    │   └── plot_toxicity_vs_bin.R
    ├── extended_data_figure_3/
    │   └── plot_extended_data_figure_3.R
    ├── extended_data_figure_4/
    │   └── plot_extended_figure_4.R
    ├── extended_data_figure_5/
    │   └── plot_extended_data_figure_5.R
    ├── extended_data_figure_6/
    │   ├── plot_extended_data_figure_6.R
    │   └── print_table_interactions_validation_dataset.R
    ├── extended_data_figure_7/
    │   └── plot_extended_data_figure_7.R
    ├── extended_data_figure_8/
    │   └── plot_extended_data_figure_8.R
    ├── extended_data_table_8/
    │   └── plot_extended_data_table_8_figure.R
    ├── figure1.R
    ├── figure2.R
    ├── figure_1/
    │   └── plot_figure_1.R
    ├── figure_2/
    │   └── plot_figure_2.R
    ├── figure_3/
    │   ├── plot_figure_3.R
    │   ├── plot_participation_vs_bin.R
    │   ├── plot_slopes_correlation_toxicity_and_participation.R
    │   └── print_table_interaction_pvalue.R
    ├── figure_4/
    │   └── plot_figure_4.R
    └── turnover_between_bins/
        ├── plot_turnover_between_bins.R
        └── plot_turnover_between_bins_post.R
```

To enhance reproducibility, we provided information within each file to support readers in their activity.
