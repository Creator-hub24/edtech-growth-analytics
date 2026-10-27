"""Download the Open University Learning Analytics Dataset (OULAD) into data/raw/.

Source: UCI ML Repository mirror (dataset 349). Original: https://analyse.kmi.open.ac.uk/open-dataset
License: CC BY 4.0. Citation: Kuzilek J., Hlosta M., Zdrahal Z. (2017) Open University Learning
Analytics dataset. Scientific Data 4, 170171. https://doi.org/10.1038/sdata.2017.171
Raw files (~450 MB unzipped, mostly studentVle.csv) are git-ignored.
"""
import io, urllib.request, zipfile
from pathlib import Path

URL = "https://archive.ics.uci.edu/static/public/349/open+university+learning+analytics+dataset.zip"
RAW = Path(__file__).resolve().parent / "raw"

if __name__ == "__main__":
    RAW.mkdir(exist_ok=True)
    if (RAW / "studentVle.csv").exists():
        print("OULAD already present in", RAW); raise SystemExit
    print("Downloading", URL)
    data = urllib.request.urlopen(URL, timeout=600).read()
    zipfile.ZipFile(io.BytesIO(data)).extractall(RAW)
    print("Extracted:", sorted(p.name for p in RAW.iterdir()))
