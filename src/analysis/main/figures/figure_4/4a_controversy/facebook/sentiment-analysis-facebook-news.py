# %%
# Download the model
from transformers import AutoTokenizer, AutoModelForSequenceClassification, pipeline
import os
import pandas as pd
import numpy as np
import torch
import sys

# %%
torch.cuda.set_per_process_memory_fraction(0.4)

# %%
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
device

# %%
chunk_number = int(sys.argv[1])
print(f"Working with chunk number: {chunk_number}")

# %%
controversy_filename = "/media/cdcs/DATA1/NEW_toxicity_in_online_conversations/data/Results/figure_4/Facebook/facebook_news_controversy_comments_to_label_for_sentiment_analysis.parquet"
output_filename = ""

# %%
df_controversy = pd.read_parquet(controversy_filename)
df_controversy = df_controversy[df_controversy['text'].notnull()]

# %%
length = df_controversy.shape[0]
chunk_size = int(length/4)


# %%
begin = (chunk_number*chunk_size)
end = (((chunk_number+1)*chunk_size))

if end >= length:
    end = length
    
df_controversy = df_controversy.iloc[begin:end, ]
output_filename = f"/media/cdcs/DATA1/NEW_toxicity_in_online_conversations/data/Results/figure_4/Facebook/facebook_news_controversy_comments_labeled_with_sentiment_{chunk_number}_chunk.parquet"
print(f"Labelling data from index {begin} to {end}")
print(f"Output filename: {output_filename}")

# %%
if os.path.exists("media/cdcs/DATA1/NEW_toxicity_in_online_conversations/src/transformation/figure_4/4a_controversy/bert-base-multilingual-uncased-sentiment") == False:
    
    # Download the model
    tokenizer = AutoTokenizer.from_pretrained("nlptown/bert-base-multilingual-uncased-sentiment")
    model = AutoModelForSequenceClassification.from_pretrained("nlptown/bert-base-multilingual-uncased-sentiment")

    # Store the model
    tokenizer.save_pretrained("media/cdcs/DATA1/NEW_toxicity_in_online_conversations/src/transformation/figure_4/4a_controversy/bert-base-multilingual-uncased-sentiment")
    model.save_pretrained("media/cdcs/DATA1/NEW_toxicity_in_online_conversations/src/transformation/figure_4/4a_controversy/bert-base-multilingual-uncased-sentiment")

# %%
# Load the offline models
tokenizer = AutoTokenizer.from_pretrained("media/cdcs/DATA1/NEW_toxicity_in_online_conversations/src/transformation/figure_4/4a_controversy/bert-base-multilingual-uncased-sentiment")
model = AutoModelForSequenceClassification.from_pretrained("media/cdcs/DATA1/NEW_toxicity_in_online_conversations/src/transformation/figure_4/4a_controversy/bert-base-multilingual-uncased-sentiment").to(device)

# %%
classifier = pipeline('sentiment-analysis', model=model, tokenizer=tokenizer, return_all_scores=True, device=0, max_length = 512, truncation=True)

# %%
rating_dict = {'1 star' : 5,
               '2 stars' : 4,
               '3 stars' : 3,
               '4 stars' : 2,
               '5 stars' : 1}

normalize_between_0_and_1 = lambda x: (x - min(x)) / (max(x) - min(x))


# %%
def get_rating(x):
    return rating_dict[x['label']]

def score(x):
    sentiment_score = sum(item['score'] * rating_dict[item['label']] for item in x[0])
    return sentiment_score

# %%
def classify(x):
    try:
        results = classifier(x)
        return results
    except:
        print(f"An error happened for: {x}")
        return None 

# %%

start = 0
end = chunk_size
step = 20000

# %%
scorings = []
for i in range(start, end, step):
    try:
        print(f"From {i} to {i+step}")

        print("Scoring")
        results = list()
        for index, x in enumerate(df_controversy.iloc[i:i+step, ]['text']):

            try:
                element_classification = classifier([x])
                results.append(element_classification)
            except Exception as e:
                print(f"An error happened at chunk {index}: {e}")

        print("Appending")
        for result in results:
            if result is None:
                next
            else:
                scorings.append(score(result))

        print(f"We now have a total of {len(scorings)} comments scored.")
    except Exception as e:
        print(f"{e}")



# %%
df_controversy_comments_with_sentiment = pd.DataFrame({
    'comment_id' : df_controversy['comment_id'],
    'text' : df_controversy['text'],
    'sentiment_score' : scorings
})
print(f"Saving {output_filename}")
df_controversy_comments_with_sentiment.to_parquet(output_filename)

# # %%
# output_filename

# # %%
# scorings = np.array(scorings)
# normalized_scorings = (scorings - scorings.min()) / (scorings.max() - scorings.min())

# # %%
# df_controversy_comments_with_sentiment = pd.DataFrame({
#     'comment_id' : df_controversy['comment_id'],
#     'text' : df_controversy['text'],
#     'sentiment_score' : normalized_scorings
# })
# df_controversy_comments_with_sentiment.to_parquet(output_filename)

# # %% [markdown]
# # 

# # %%
# output_filename


