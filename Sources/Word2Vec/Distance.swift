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

public final class Distance {
    
    private let vocab: UnsafeMutablePointer<CChar>
    private let vocabCount: Int
    private let M: UnsafeMutablePointer<Float>
    private let MCount: Int
    private let modelWords: Int
    private let modelSize: Int
    public init(modelPath: String) {
        var modelWords_: Int64 = 0
        var modelSize_: Int64 = 0
        
        let file = fopen(modelPath, "rb")
        fscanf_long(file, &modelWords_)
        fscanf_long(file, &modelSize_)
        modelWords = Int(modelWords_)
        modelSize = Int(modelSize_)
        
        let vocabCount = modelWords * MAX_VOCAB_LEN
        let vocab = UnsafeMutablePointer<CChar>.allocate(capacity: vocabCount)
        let MCount = modelWords * modelSize
        let M = UnsafeMutablePointer<Float>.allocate(capacity: MCount)
        do {
            
            for b in 0..<modelWords {
                var a = 0
                while true {
                    vocab[b * MAX_VOCAB_LEN + a] = CChar(fgetc(file))
                    if feof(file) > 0 || (vocab[b * MAX_VOCAB_LEN + a] == CONST_SPACE) {
                        break
                    }
                    if (a < MAX_VOCAB_LEN) && (vocab[b * MAX_VOCAB_LEN + a] != CONST_NEWLINE) {
                        a += 1
                    }
                }
                vocab[b * MAX_VOCAB_LEN + a] = 0
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
        
        fclose(file)
        
        
        self.vocabCount = vocabCount
        self.vocab = vocab
        self.MCount = MCount
        self.M = M
    }
    
    deinit {
        vocab.deallocate(capacity: vocabCount)
        M.deallocate(capacity: MCount)
    }
    
    func calcDistance(words: String, limit: Int) {
        let countToShow = limit
        
        let bestd = UnsafeMutablePointer<Float>.allocate(capacity: countToShow)
        defer {
            bestd.deallocate(capacity: countToShow)
        }
        
        for a in 0..<countToShow {
            bestd[a] = 0
        }
        
        //for (a = 0; a < N; a++) bestw[a] = (char *)malloc(max_size * sizeof(char));
        let bestw: [UnsafeMutablePointer<CChar>] = (0..<countToShow).map { _ in
            UnsafeMutablePointer<CChar>.allocate(capacity: MAX_STRING_LEN)
        }
        defer {
            bestw.forEach {
                $0.deallocate(capacity: MAX_STRING_LEN)
            }
        }
        
        for a in 0..<countToShow {
            bestw[a][0] = 0
        }
        
        let st1 = UnsafeMutablePointer<CChar>.allocate(capacity: MAX_STRING_LEN)
        defer {
            st1.deallocate(capacity: MAX_STRING_LEN)
        }
        var a = 0
        words.withCString { (buf) -> Void in
            while true {
                st1[a] = buf[a]
                if ((st1[a] == CONST_NEWLINE) || (a >= MAX_STRING_LEN - 1)) {
                    st1[a] = 0
                    break
                }
                a += 1
            }
        }
        let st: [UnsafeMutablePointer<CChar>] = (0..<100).map { _ in
            UnsafeMutablePointer<CChar>.allocate(capacity: MAX_STRING_LEN)
        }
        defer {
            st.forEach {
                $0.deallocate(capacity: MAX_STRING_LEN)
            }
        }
        //if (!strcmp(st1, "EXIT")) break;
        var cn = 0
        var b = 0
        var c = 0
        while true {
            st[cn][b] = st1[c]
            b += 1
            c += 1
            st[cn][b] = 0
            if (st1[c] == 0) {
                break
            }
            if (st1[c] == CONST_SPACE) {
                cn += 1
                b = 0
                c += 1
            }
        }
        cn += 1
        var bi = [Int](repeating: 0, count: 100)
        for a in 0..<cn {
            for bb in 0..<modelWords {
                b = bb
                if strcmp(&vocab[bb * MAX_VOCAB_LEN], st[a]) == 0 {
                    break
                }                
            }
            if b == modelWords {
                b = -1
            }
            bi[a] = b
            let str = String(format: "Word: %s  Position in vocabulary: %lld", st[a], bi[a])
            print(str)
            if b == -1 {
                print("Out of dictionary word!")
                break
            }
        }
        
        if (b == -1) {
            return
        }
        print("\n                                              Word       Cosine distance\n------------------------------------------------------------------------")
        var vec = [Float].init(repeating: 0, count: MAX_STRING_LEN)
        for a in 0..<modelSize {
            vec[a] = 0
        }
        for b in 0..<cn {
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
        for a in 0..<countToShow {
            bestd[a] = -1
            bestw[a][0] = 0
        }
        for c in 0..<modelWords {
            a = 0
            for b in 0..<cn {
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
                        strcpy(bestw[d], bestw[d - 1])
                        d -= 1
                    }
                    bestd[a] = dist
                    strcpy(bestw[a], &vocab[c * MAX_VOCAB_LEN]);
                    break;
                }
            }
        }
        for a in 0..<countToShow {
            let str = String(format: "%50s\t\t%f", bestw[a], bestd[a])
            print(str)
        }
    }
}
