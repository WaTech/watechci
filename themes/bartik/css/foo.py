import requests

url = 'http://54.183.116.233:8000'
info = requests.get(url).text
lines = info.splitlines()

for linenum, line in enumerate(lines):
	print "FOO!"
	print line
