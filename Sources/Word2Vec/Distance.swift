//
//  Distance.swift
//  word2vec-swift
//
//  Created by Yusuke Ito on 5/4/17.
//
//

import Foundation
import CWord2Vec

fileprivate let MAX_VOCAB_LEN = 50 // max_w
fileprivate let MAX_STRING_LEN = 2000 // max_size


public final class Distance {
    
    private let vocab: UnsafeMutablePointer<CChar>
    private let vocabCount: Int
    private let M: UnsafeMutablePointer<Float32>
    private let MCount: Int
    public init(modelPath: String) {
        var modelWords_: Int64 = 0
        var modelSize_: Int64 = 0
        
        let file = fopen(modelPath, "rb")
        fscanf_long(file, &modelWords_)
        fscanf_long(file, &modelSize_)
        let modelWords = Int(modelWords_)
        let modelSize = Int(modelSize_)
        
        let vocabCount = modelWords * MAX_VOCAB_LEN
        let vocab = UnsafeMutablePointer<CChar>.allocate(capacity: vocabCount)
        let MCount = modelWords * modelSize
        let M = UnsafeMutablePointer<Float32>.allocate(capacity: MCount)
        do {
            
            for b in 0..<modelWords {
                var a = 0
                while true {
                    vocab[b * MAX_VOCAB_LEN + a] = CChar(fgetc(file))
                    if feof(file) > 0 || (vocab[b * MAX_VOCAB_LEN + a] == CChar(" ".utf8CString[0])) {
                        break
                    }
                    if (a < MAX_VOCAB_LEN) && (vocab[b * MAX_VOCAB_LEN + a] != CChar("\n".utf8CString[0])) {
                        a += 1
                    }
                }
                vocab[b * MAX_VOCAB_LEN + a] = 0;
                for a in 0..<modelSize {
                    fread(&M[a + b * modelSize], MemoryLayout<Float32>.size, 1, file)
                }
                var len = 0 as Float
                for a in 0..<modelSize {
                    len += M[a + b * modelSize] * M[a + b * modelSize]
                }
                len = sqrt(len)
                for a in 0..<modelSize {
                    M[a + b * modelSize] /= len
                }
            }
        }
        
        fclose(file)
        
        
        self.vocabCount = vocabCount
        self.vocab = vocab
        self.MCount = MCount
        self.M = M
    }
}
