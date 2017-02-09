scoring = require('./scoring')

feedback =
  default_feedback:
    warning: ''
    suggestions: [
      "Evite frases comuns"
    ]

  get_feedback: (score, sequence) ->
    # starting feedback
    return @default_feedback if sequence.length == 0

    # no feedback if score is good or great.
    return if score > 2
      warning: ''
      suggestions: []

    # tie feedback to the longest match for longer sequences
    longest_match = sequence[0]
    for match in sequence[1..]
      longest_match = match if match.token.length > longest_match.token.length
    feedback = @get_match_feedback(longest_match, sequence.length == 1)
    extra_feedback = 'Adicione mais uma ou duas palavras. Palavras pouco comuns são melhores'
    if feedback?
      feedback.suggestions.unshift extra_feedback
      feedback.warning = '' unless feedback.warning?
    else
      feedback =
        warning: ''
        suggestions: [extra_feedback]
    feedback

  get_match_feedback: (match, is_sole_match) ->
    switch match.pattern
      when 'dictionary'
        @get_dictionary_match_feedback match, is_sole_match

      when 'spatial'
        layout = match.graph.toUpperCase()
        warning = if match.turns == 1
          'Sequência de teclas em ordem crescente ou descrente não são seguras'
        else
          'Padrões de teclas não são seguras'
        warning: warning
        suggestions: [
          'Use diferentes padrões de teclas'
        ]

      when 'repeat'
        warning = if match.base_token.length == 1
          'Repetições como "aaa" não são seguras'
        else
          'Repetições como "abcabcabc" não são mais seguras que "abc"'
        warning: warning
        suggestions: [
          'Evite palavras e caracteres repetidos'
        ]

      when 'sequence'
        warning: 'Sequências como "abc" ou "6543" não são seguras'
        suggestions: [
          'Evite sequências'
        ]

      when 'regex'
        if match.regex_name == 'recent_year'
          warning: "Anos recentes não são seguros"
          suggestions: [
            'Não utilize anos recentes'
            'Evite anos que estão associados com você'
          ]

      when 'date'
        warning: "Datas não são seguras"
        suggestions: [
          'Evite datas que estão associadas com você'
        ]

  get_dictionary_match_feedback: (match, is_sole_match) ->
    warning = if match.dictionary_name == 'passwords'
      if is_sole_match and not match.l33t and not match.reversed
        if match.rank <= 10
          'Essa é uma das 10 senhas mais utilizadas'
        else if match.rank <= 100
          'Essa é uma das 100 senhas mais utilizadas'
        else
          'Essa senha é muito comum'
      else if match.guesses_log10 <= 4
        'Essa senha é comumente utilizada'
    else if match.dictionary_name == 'english_wikipedia'
      if is_sole_match
        'Palavras comuns não são seguras'
    else if match.dictionary_name in ['surnames', 'male_names', 'female_names']
      if is_sole_match
        'Nomes e sobrenomes não são seguros'
      else
        'Utilizar nomes e sobrenomes não é seguros'
    else
      ''
      
    suggestions = []
    word = match.token
    if word.match(scoring.START_UPPER)
      suggestions.push "Palavras em letra maiúscula não ajudam na segurança"
    else if word.match(scoring.ALL_UPPER) and word.toLowerCase() != word
      suggestions.push "Palavras em letra maiúscula não ajudam na segurança"

    if match.reversed and match.token.length >= 4
      suggestions.push "Palavras invertidas não são seguras"
    if match.l33t
      suggestions.push "Substituições previsíveis como '@' em vez de 'a' não ajudam na segurança de sua senha"

    result =
      warning: warning
      suggestions: suggestions
    result

module.exports = feedback
