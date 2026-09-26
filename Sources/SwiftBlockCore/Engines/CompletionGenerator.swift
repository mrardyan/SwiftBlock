import Foundation

public enum ShellType: String, CaseIterable {
    case zsh
    case bash
    case fish
}

public struct CompletionGenerator {
    public static func generate(for shell: ShellType) -> String {
        let brickCommands = BrickRegistry.allBricks.map { $0.commandName }.sorted()
        let brickList = brickCommands.joined(separator: " ")
        
        switch shell {
        case .zsh:
            return """
            #compdef swiftblock

            _swiftblock() {
                local -a subcommands
                subcommands=(
                    'baseplate:Lay down a new SwiftUI or Vapor project baseplate'
                    'snap:Snap a foundation or architectural brick'
                    'kit:Manage and execute multi-brick composition kits'
                    'box:Manage remote team brick repositories'
                    'doctor:Diagnose SwiftBlock environment and configuration'
                    'ide:Generate IDE tasks and Makefile shortcuts'
                    'rename:Refactor and rename project names'
                    'completion:Generate shell autocompletion script'
                )

                local -a bricks
                bricks=(\(brickCommands.map { "'\($0)'" }.joined(separator: " ")))

                local -a kits
                kits=('clean-feature' 'feature' 'simple' 'data')

                _arguments -C \\
                    '1: :->subcommand' \\
                    '*:: :->args'

                case $state in
                    subcommand)
                        _describe -t subcommands 'swiftblock subcommands' subcommands
                        ;;
                    args)
                        case $words[1] in
                            snap|use|add)
                                _arguments \\
                                    '1:brick:(\(brickList))' \\
                                    '--flavor=[Select flavor option]:flavor:' \\
                                    '--with-optional=[Optional dependencies]:deps:' \\
                                    '--all-optional[Snap all optional dependencies]' \\
                                    '--no-deps[Skip automatic resolution of dependencies]' \\
                                    '--dry-run[Simulate generation without writing to disk]' \\
                                    '--var=[Custom template variable]:key=val:'
                                ;;
                            kit)
                                _arguments \\
                                    '1:subcommand:(run add create list)' \\
                                    '2:kit:($kits)'
                                ;;
                            baseplate|new|init)
                                _arguments \\
                                    '--tool=[Build tool generator]:(tuist xcodegen)' \\
                                    '--baseplate=[Baseplate starter]:(swiftui vapor)' \\
                                    '--test-framework=[Unit test framework]:(swift-testing xctest)' \\
                                    '--dry-run[Simulate generation]'
                                ;;
                            box)
                                _arguments \\
                                    '1:subcommand:(add list update remove validate publish)'
                                ;;
                            completion)
                                _arguments \\
                                    '1:shell:(zsh bash fish)'
                                ;;
                        esac
                        ;;
                esac
            }

            _swiftblock "$@"
            """

        case .bash:
            return """
            # bash completion for swiftblock
            _swiftblock_completions() {
                local cur prev subcommands bricks
                cur="${COMP_WORDS[COMP_CWORD]}"
                prev="${COMP_WORDS[COMP_CWORD-1]}"
                subcommands="baseplate snap kit box doctor ide rename completion"
                bricks="\(brickList)"

                if [ $COMP_CWORD -eq 1 ]; then
                    COMPREPLY=( $(compgen -W "${subcommands}" -- ${cur}) )
                    return 0
                fi

                case "${prev}" in
                    snap|use|add)
                        COMPREPLY=( $(compgen -W "${bricks} --flavor --with-optional --all-optional --no-deps --dry-run" -- ${cur}) )
                        return 0
                        ;;
                    completion)
                        COMPREPLY=( $(compgen -W "zsh bash fish" -- ${cur}) )
                        return 0
                        ;;
                    --tool)
                        COMPREPLY=( $(compgen -W "tuist xcodegen" -- ${cur}) )
                        return 0
                        ;;
                    --baseplate)
                        COMPREPLY=( $(compgen -W "swiftui vapor" -- ${cur}) )
                        return 0
                        ;;
                    *)
                        ;;
                esac
            }
            complete -F _swiftblock_completions swiftblock
            """

        case .fish:
            return """
            # fish completion for swiftblock
            complete -c swiftblock -f
            complete -c swiftblock -n "__fish_use_subcommand" -a "baseplate snap kit box doctor ide rename completion"
            complete -c swiftblock -n "__fish_seen_subcommand_from snap use add" -a "\(brickList)"
            complete -c swiftblock -n "__fish_seen_subcommand_from completion" -a "zsh bash fish"
            complete -c swiftblock -l flavor -d "Flavor selection key=val"
            complete -c swiftblock -l with-optional -d "Optional dependencies to snap"
            complete -c swiftblock -l all-optional -d "Snap all optional dependencies"
            complete -c swiftblock -l no-deps -d "Skip automatic dependency resolution"
            complete -c swiftblock -l dry-run -d "Simulate generation without writing"
            """
        }
    }
}
