import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq
import json
import ast
from tqdm import tqdm

def extract_dictionary_from_attachment(text: str) -> str:
    try:
        text: dict = ast.literal_eval(str(text))
        if "url" in text.values():
            if not isinstance(text["value"], dict):
                raise TypeError("text[value] is formatted poorly")
            if "source" in text["value"]:
                return text["value"]["source"]
    except:
        pass

    return None

print('Loading json')
df = pd.read_parquet("/media/cdcs/DATA1/NEW_toxicity_in_online_conversations/data/Labeled/Gab/gab_labeled_data_unified_with_link.parquet")

print('Converting json')
attachment_source = list()

for text in tqdm(df["attachment"]):
    result = extract_dictionary_from_attachment(text)
    attachment_source.append(result)

df['attachment_source'] = attachment_source

print('Saving result')
df.to_parquet("/media/cdcs/DATA1/NEW_toxicity_in_online_conversations/data/Labeled/Gab/gab_post_and_comments_labeled_with_converted_json.parquet")
