//
//  utils.c
//  word2vec-swift
//
//  Created by Yusuke Ito on 5/4/17.
//
//

#include <stdio.h>
#include <string.h>

void fscanf_long(FILE* file, long long* dst)
{
    fscanf(file, "%lld", dst);
}
