
Legacy scripts 

To check access script below should return tables: 

```py 
import requests
import pandas as pd
url = 'http://www.worldgovernmentbonds.com/country/new-zealand'
html = requests.get(url).content
df_list = pd.read_html(html)
df_list
```

The old github actions workflow yaml was: 

```
on:
  workflow_dispatch:
  schedule:
  - cron: "26 1 * * 6"
jobs:
  import-data:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: r-lib/actions/setup-r@v2
    - uses: r-lib/actions/setup-renv@v2
    - run: Rscript run.R
    - name: Commit and push changes
      uses: devops-infra/action-commit-push@master
      with:
        github_token: ${{ secrets.TOKEN }}
        commit_message: Push update back to repo
```
