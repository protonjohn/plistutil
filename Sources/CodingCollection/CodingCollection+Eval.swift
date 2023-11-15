public extension CodingCollection {
    internal enum Symbol: String {
        case cases = ".cases"
        case contexts = ".contexts"

        case ifCase = ".if"
        case ifSetCase = ".ifSet"

        case contextMap = ".map"
        case contextInclude = ".include"
        case contextExclude = ".exclude"

        static let applicationOrder: [Self] = [
            .cases,
            .contexts,
        ]

        var keyValue: CodingCollection {
            .string(rawValue)
        }
    }

    static let debugFlag: Self = "debug_eval_print"

    private func debugPrint(
        _ string: String
    ) {
        guard (try? self[Self.debugFlag]) != nil else { return }
        print(string)
    }

    mutating private func evalCases(
        arguments: Self,
        cases: Self
    ) throws {
        guard case let .list(cases) = cases else {
            throw CodingCollectionError.expectedList
        }

        for caseStep in cases {
            guard case let .dictionary(caseDict) = caseStep else {
                throw CodingCollectionError.invalidCaseStep(caseStep)
            }

            if let caseName = caseDict[Symbol.ifCase.keyValue] {
                guard caseDict[Symbol.ifSetCase.keyValue] == nil else {
                    throw CodingCollectionError.invalidCaseStep(caseStep)
                }
                guard let value = try self[caseName] else {
                    throw CodingCollectionError.valueNotFound(caseName, in: self, for: caseStep)
                }
                guard let caseValue = caseDict[value] else {
                    throw CodingCollectionError.valueNotFound(value, in: caseStep, for: caseStep)
                }
                debugPrint("Setting overrides for argument \(caseName) = \(value)...")
                try eval(arguments: arguments, dictionary: caseValue)
            } else if let caseName = caseDict[Symbol.ifSetCase.keyValue] {
                guard (try? self[caseName]) != nil else {
                    continue
                }
                debugPrint("Setting overrides for argument \(caseName)...")
                try eval(arguments: arguments, dictionary: caseStep)
            }
        }
    }

    mutating private func evalContexts(
        arguments: Self,
        contexts: Self
    ) throws {
        guard case var .dictionary(selfDict) = self else {
            throw CodingCollectionError.expectedDictionary
        }
        guard case let .dictionary(contexts) = contexts else {
            throw CodingCollectionError.expectedDictionary
        }

        for (contextKey, context) in contexts {
            guard case let .string(contextName) = contextKey else {
                throw CodingCollectionError.expectedString
            }

            guard case let .dictionary(context) = context else {
                throw CodingCollectionError.expectedDictionary
            }

            let contextDictKey: CodingCollection = .string("context_\(contextName)")
            let contextDictValue = selfDict[contextDictKey] ?? [:]
            let argumentsContextDict = try? arguments[contextDictKey]
            guard case var .dictionary(contextDict) = contextDictValue else {
                throw CodingCollectionError.expectedDictionary
            }

            for (contextAction, actionItems) in context {
                guard let symbol = Symbol(keyValue: contextAction) else {
                    throw CodingCollectionError.unrecognizedSymbol(String(describing: contextKey.value))
                }

                switch symbol {
                case .contextMap:
                    guard case .dictionary(let actionDict) = actionItems else {
                        throw CodingCollectionError.expectedDictionary
                    }

                    for (mapKey, aliasKey) in actionDict {
                        guard let item = try? self[mapKey],
                            (try? argumentsContextDict?[mapKey]) == nil else { continue }
                        contextDict[aliasKey] = item
                    }
                case .contextInclude:
                    guard case .list(let actionList) = actionItems else {
                        throw CodingCollectionError.expectedList
                    }

                    for includeKey in actionList {
                        guard let item = try? self[includeKey],
                            (try? argumentsContextDict?[includeKey]) == nil else { continue }
                        contextDict[includeKey] = item
                    }
                case .contextExclude:
                    guard case .list(let actionList) = actionItems else {
                        throw CodingCollectionError.expectedList
                    }
                    let itemHash = Set(actionList)

                    contextDict.merge(
                        selfDict.filter {
                            if case .string(let string) = $0.key, string.hasPrefix("context_") {
                                return false
                            }
                            return !itemHash.contains($0.key) && (try? argumentsContextDict?[$0.key]) == nil
                        },
                        uniquingKeysWith: { _, rhs in rhs }
                    )
                default:
                    throw CodingCollectionError.unrecognizedSymbol(symbol.rawValue)
                }
            }
            selfDict[contextDictKey] = .dictionary(contextDict)
        }
        self = .dictionary(selfDict)
    }

    mutating private func eval(
        arguments: Self,
        key: Self,
        item: Self
    ) throws {
        guard case .dictionary(var optionsDict) = self,
              case .dictionary(let originalOptions) = arguments else {
            throw CodingCollectionError.expectedDictionary
        }

        guard let keyString = key.value as? String else {
            throw CodingCollectionError.expectedSymbol
        }

        guard let symbol = Symbol(rawValue: keyString) else {
            if let value = originalOptions[key] {
                debugPrint("Arguments set \(keyString) = \(value), overriding evaluated value \(item).")
            } else {
                optionsDict[key] = item
            }
            self = .dictionary(optionsDict)
            return
        }

        switch symbol {
        case .cases:
            try evalCases(arguments: arguments, cases: item)

        case .contexts:
            try evalContexts(arguments: arguments, contexts: item)

        default:
            throw CodingCollectionError.unrecognizedSymbol(symbol.rawValue)
        }
    }

    mutating private func eval(
        arguments: Self,
        dictionary: Self
    ) throws {
        guard case .dictionary(let dictionary) = dictionary else {
            throw CodingCollectionError.expectedDictionary
        }

        var symbols: [Symbol: (key: Self, value: Self)] = [:]
        for (key, value) in dictionary {
            if case let .string(symbolName) = key,
               let symbol = Symbol(rawValue: symbolName) {
                symbols[symbol] = (key, value)
            } else {
                try eval(arguments: arguments, key: key, item: value)
            }
        }

        for symbol in Symbol.applicationOrder {
            guard let (key, value) = symbols[symbol] else { continue }
            try eval(arguments: arguments, key: key, item: value)
        }
    }

    mutating func apply(caseDict: Self, preservingOriginalValues: Bool) throws {
        try eval(arguments: preservingOriginalValues ? self : [:], dictionary: caseDict)
    }
}

extension CodingCollection.Symbol {
    init?(keyValue: CodingCollection) {
        guard case let .string(string) = keyValue else {
            return nil
        }
        guard let result = Self(rawValue: string) else {
            return nil
        }
        self = result
    }
}
