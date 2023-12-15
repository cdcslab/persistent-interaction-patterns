import pandas as pd
import requests
import json
import csv

def extract_urls(row : str):
    try:
        row = row.replace("'", '"')
        entities = json.loads(row)
        
        
        for url_element in entities['urls']:
            url, expanded_url = None, None
            if 'twitter' in url_element['expanded_url'].lower() or \
                'instagram' in url_element['expanded_url'].lower() or \
                    'facebook' in url_element['expanded_url'].lower() or \
                        'youtube' in url_element['expanded_url'].lower() or \
                            'youtu.be' in url_element['expanded_url'].lower():
                continue
             
            try:
                url = url_element.get('url')
            except:
                url = None
                
            try:
                expanded_url = url_element.get('expanded_url')
            except:
                expanded_url = None
            
            return expanded_url
    except Exception as e:
        return None

def expand_url(row, comment_id, output_file):
    try:
        expanded_url = extract_urls(row)
        
        if expanded_url is not None:
            response = requests.head(expanded_url, allow_redirects=True)
            if response.status_code == 200:
                # Salva il risultato in un file CSV
                with open(output_file, 'a', newline='') as csv_file:
                    csv_writer = csv.writer(csv_file)
                    csv_writer.writerow([comment_id, response.url])
                return response.url
            else:
                return f"Error: Status code {response.status_code}"
    except requests.RequestException as e:
        return f"Error: {e}"

def process_urls_from_parquet(file_path, attachment_column, output_file):
    # Leggi il file Parquet in un DataFrame
    df = pd.read_parquet(file_path)
    
    # Espandi gli URL applicando la funzione a livello di riga
    df['expanded_url'] = df.apply(lambda row: expand_url(row[attachment_column], row["comment_id"], output_file), axis=1)
    
    return df

# Example usage:
output_file = "/media/cdcs/DATA1/NEW_toxicity_in_online_conversations/data/Labeled/Twitter/twitter_expanded_urls.csv"
expanded_df = process_urls_from_parquet("/media/cdcs/DATA1/NEW_toxicity_in_online_conversations/data/Labeled/Twitter//twitter_vaccines_labeled_with_urls_expanded.parquet", 
                                        'entities',
                                        output_file)