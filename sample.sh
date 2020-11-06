set -o xtrace

sudo kubectl exec -it  docker-doc-dev -- nslookup attestationcovid.site
sudo kubectl exec -it  docker-doc-dev -- ping -4 -c 3 attestationcovid.site
sudo kubectl exec -it  docker-doc-dev -- ping -6 -c 3 attestationcovid.site
sudo kubectl exec -it  docker-doc-dev -- traceroute attestationcovid.site
sudo kubectl exec -it  docker-doc-dev -- nc -vz attestationcovid.site 443
sudo kubectl exec -it  docker-doc-dev -- curl -L attestationcovid.site | cut -c-200