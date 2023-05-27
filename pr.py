#!/usr/bin/python3
import os
import json
import argparse
from atlassian import Bitbucket

# https://atlassian-python-api.readthedocs.io/bitbucket.html
# https://atlassian-python-api.readthedocs.io/index.html

# pip3 install atlassian-python-api 
# Добавить для запуска в клауде  --index-url https://spo.solution.sbt/python/simple/ --trusted-host spo.solution.sbt


parser = argparse.ArgumentParser(description="Make pull requests")
parser.add_argument('--user', help='bitbucket username')
parser.add_argument('--passwd', help='bitbucket password')
parser.add_argument('--src_branch', help='bitbucket source branch')

args = parser.parse_args()
src_branch = args.src_branch

url = os.popen('git config --get remote.origin.url')
url = url.read()
print(url)

class GitBucket:
    def __init__(self, url):
        self.__parse_git_addr(url) 
        self.username = args.user
        self.password = args.passwd
        #self.src_branch = args.src_branch
        self.bitbucket = Bitbucket(url=self.addr, username=self.username, password=self.password)

    def get_pr(self):
        for i in self.bitbucket.get_pull_requests(self.project, self.repo, state='OPEN', order='newest', limit=100, start=0):
            self.__pretty_json(i)

    def make_pr(self, src_branch, dest_branch='master'):
        pr = self.bitbucket.open_pull_request(source_project=self.project, \
                source_repo=self.repo, \
                dest_project=self.project, \
                dest_repo=self.repo, \
                source_branch=src_branch, \
                destination_branch=dest_branch, \
                title='autoPR', \
                description='autoPR')
        self.__pretty_json(pr)

    def __parse_git_addr(self, data):
        if '@' in data:# and data.startswith('http') and data.endswith('.git'):
            http = data.split('//')[0]
            d = data.split('@')[1].split('/')
            self.addr = "{}//{}/{}".format(http, d[0], d[1])
            self.project = d[3]
            self.repo = d[-1].split('.')[0]

    def __pretty_json(self, data):
        # parsed = json.loads(your_json)
        print(json.dumps(data, indent=4))

if __name__ == '__main__':
    gb = GitBucket(url)
    gb.make_pr(src_branch)
    # gb.get_pr()
