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

fileprivate let CONST_SPACE = CChar(" ".utf8CString[0])
fileprivate let CONST_NEWLINE = CChar("\n".utf8CString[0])

typealias ModelIndex = Int

public final class Distance {

    
    private let vocab: [String]
    private let vocabIndex: [String: ModelIndex] // count will be `modelWords`
    private let M: UnsafeMutablePointer<Float> // the model
    private let MCount: Int
    private let modelWords: Int
    private let modelSize: Int
    public init(modelPath: String) {
        var modelWords_: Int64 = 0
        var modelSize_: Int64 = 0
        
        let file = fopen(modelPath, "rb") // load a model binary
        defer {
            fclose(file)
        }
        fscanf_long(file, &modelWords_)
        fscanf_long(file, &modelSize_)
        modelWords = Int(modelWords_)
        modelSize = Int(modelSize_)
        
        //let vocabCount = modelWords * MAX_VOCAB_LEN
        // row=word length=MAX_VOCAB_LEN
        // column length=modelWords
        //let vocab = UnsafeMutablePointer<CChar>.allocate(capacity: vocabCount)
        var vocabIndex = [:] as [String: Int]
        var vocab = [] as [String]
        
        MCount = modelWords * modelSize
        M = UnsafeMutablePointer<Float>.allocate(capacity: MCount)
        do {
            let vocabBuf = UnsafeMutablePointer<CChar>.allocate(capacity: MAX_VOCAB_LEN)
            defer {
                vocabBuf.deallocate(capacity: MAX_VOCAB_LEN)
            }
            for b in 0..<ModelIndex(modelWords) { // b is column
                
                // parse string from the binary
                var i = 0
                while true {
                    vocabBuf[i] = CChar(fgetc(file))
                    if feof(file) > 0 || (vocabBuf[i] == CONST_SPACE) {
                        break
                    }
                    if (i < MAX_VOCAB_LEN) && (vocabBuf[i] != CONST_NEWLINE) {
                        i += 1
                    }
                }
                vocabBuf[i] = 0 // null terminated
                let str = String(utf8String: vocabBuf)!
                vocabIndex[str] = b
                vocab.append(str)
                
                for a in 0..<modelSize {
                    fread(&M[a + b * modelSize], MemoryLayout<Float>.size, 1, file)
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
        self.vocab = vocab
        self.vocabIndex = vocabIndex
    }
    
    deinit {
        M.deallocate(capacity: MCount)
    }
    
    func calcDistance(words: [String], limit: Int) {
        let countToShow = limit
        
        // 1. find model index of the words
        var bi = [Int](repeating: 0, count: words.count) // bi is vocab index for each words
        for (i, word) in words.enumerated() {
            if let posIndex = vocabIndex[word] {
                bi[i] = posIndex
                let str = String(format: "Word: %@  Position in vocabulary: %lld", word, posIndex)
                print(str)
            } else {
                fatalError("Out of dictionary word!")
            }
        }
        
        print("\n                                              Word       Cosine distance\n------------------------------------------------------------------------")
        
        var vec = [Float](repeating: 0, count: modelSize)
        for b in 0..<words.count {
            if bi[b] == -1 {
                continue
            }
            for a in 0..<modelSize {
                vec[a] += M[a + bi[b] * modelSize]
            }
        }
        var len = 0 as Float
        for a in 0..<modelSize {
            len += vec[a] * vec[a]
        }
        len = sqrt(len)
        for a in 0..<modelSize {
            vec[a] /= len
        }
        
        var bestd = [Float](repeating: -1, count: countToShow)
        var bestw = [String](repeating: "", count: countToShow)
        
        for c in 0..<modelWords {
            var a = 0
            for b in 0..<words.count {
                if bi[b] == c {
                    a = 1
                }
            }
            if a == 1 {
                continue
            }
            var dist = 0 as Float
            for a in 0..<modelSize {
                dist += vec[a] * M[a + c * modelSize]
            }
            for a in 0..<countToShow {
                if dist > bestd[a] {
                    var d = countToShow - 1
                    while true {
                        if d <= a {
                            break
                        }
                        bestd[d] = bestd[d - 1]
                        bestw[d] = bestw[d - 1]
                        d -= 1
                    }
                    bestd[a] = dist
                    bestw[a] = vocab[c]
                    break;
                }
            }
        }
        for a in 0..<countToShow {
            let str = String(format: "%@\t\t%f", bestw[a], bestd[a])
            print(str)
        }
    }
}
