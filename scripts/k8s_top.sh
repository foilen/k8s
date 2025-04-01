#!/bin/bash

kubectl top pod -A --sum=true | tee _top.txt
