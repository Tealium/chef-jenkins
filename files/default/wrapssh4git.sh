#!/usr/bin/env bash
export HOME=/tmp/private_code
/var/lib/jenkins/ssh -q -o "StrictHostKeyChecking=no" -i "/tmp/private_code/.ssh/id_rsa" $1 $2
/var/lib/jenkins/ssh -q -o "StrictHostKeyChecking=no" -i "/tmp/private_code/.ssh/id_rsa.pub" $1 $2

