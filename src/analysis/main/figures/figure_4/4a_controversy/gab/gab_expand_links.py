import pandas as pd
import requests
import ast
import csv
import time

def extract_dictionary_from_attachment(text: str) -> str:
    try:
        text: dict = ast.literal_eval(str(text))
        if "url" in text.values():
            if not isinstance(text["value"], dict):
                raise TypeError("text[value] is formatted poorly")
            if "url" in text["value"]:
                return text["value"]["url"]
    except:
        pass

    return None

def expand_url(row, comment_id, output_file):
    
    try:
        time.sleep(0.2)
        short_url = extract_dictionary_from_attachment(row)
        
        response = requests.head(short_url, allow_redirects=True, timeout = 10)
        if response.status_code == 200:
            print(f'Comment ID: {comment_id} Short link: {short_url} Expanded link: {response.url}')
            with open(output_file, 'a', newline='') as csv_file:
                csv_writer = csv.writer(csv_file)
                csv_writer.writerow([comment_id, response.url])
            return response.url
        else:
            return f"Error: Status code {response.status_code}"
    except requests.RequestException as e:
        return f"Error: {e}"

def process_urls_from_parquet(file_path, attachment_column, output_file, starting_index = 0):
    # Leggi il file Parquet in un DataFrame
    df = pd.read_parquet(file_path)
    df = df.iloc[starting_index:, ]
    
    # Seleziona le righe in cui 'attachment' contiene la stringa "'type': 'url'"
    df = df[df[attachment_column].str.contains("'type': 'url'", na=False)]
    
    # Espandi gli URL applicando la funzione a livello di riga
    df['expanded_url'] = df.apply(lambda row: expand_url(row[attachment_column], row["comment_id"], output_file), axis=1)
    
    return df

# Example usage:
expanded_df = process_urls_from_parquet("/media/cdcs/DATA2/NEW_toxicity_in_online_conversations/data/Labeled/Gab/gab_links_to_expand.parquet", 
                                        'attachment',
                                        "/media/cdcs/DATA2/NEW_toxicity_in_online_conversations/data/Labeled/Gab/gab_links_expanded.csv",
                                        0)
