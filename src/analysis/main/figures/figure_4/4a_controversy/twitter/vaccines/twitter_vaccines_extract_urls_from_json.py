import pandas as pd
import json

# Specifica il percorso del file Parquet
file_path = "/media/cdcs/DATA1/NEW_toxicity_in_online_conversations/data/Labeled/Twitter/twitter_vaccines_labeled_with_urls_expanded.parquet"

# Leggi il DataFrame dal file Parquet
df = pd.read_parquet(file_path)

# Funzione per estrarre i dati JSON e creare le nuove colonne
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
            
            return url, expanded_url
    except Exception as e:
        return None, None

# Applicare la funzione al DataFrame per creare le nuove colonne
df[['url', 'expanded_url']] = df['entities'].apply(extract_urls).apply(pd.Series)

# Rimuovere la colonna 'entities' se necessario
df.drop(columns=['entities'], inplace=True)

# Scrivere il DataFrame risultante nello stesso file Parquet
df.to_parquet(file_path, index=False)
