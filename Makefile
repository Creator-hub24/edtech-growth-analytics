.PHONY: all download derived sql notebook
all: download derived sql notebook
download:
	python data/download_oulad.py
derived:
	python data/build_derived.py
sql:
	python sql/run_queries.py
notebook:
	cd notebooks && jupyter nbconvert --to notebook --execute --inplace exploratory_analysis.ipynb
