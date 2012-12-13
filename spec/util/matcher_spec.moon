import Matcher from lunar.util

describe 'Matcher', ->
  it 'matches if all characters are present', ->
    c = { 'One', 'Green Fields', 'two', 'overflow' }
    m = Matcher c
    assert.same { 'One', 'Green Fields' }, m('ne')

  it 'prefers #boundary matches over straight ones over fuzzy ones', ->
    c = { 'kiss her', 'some/stuff/here', 'openssh', 'sss hhh' }
    m = Matcher c
    assert.same {
      'sss hhh',
      'some/stuff/here'
      'openssh',
      'kiss her'
    }, m('ssh')

  it 'prefers early occurring matches over ones at the end', ->
    c = { 'Two items to bind them tight', 'One item to match them' }
    m = Matcher c
    assert.same {
      'One item to match them',
      'Two items to bind them tight'
    }, m('ni')

  it 'prefers tighter matches to longer ones', ->
    c = { 'aa bb cc dd', 'zzzzzzzzzzzzzzz ad' }

    m = Matcher c
    assert.same {
      'zzzzzzzzzzzzzzz ad',
      'aa bb cc dd',
    }, m('ad')

  it '"special" characters are matched as is', ->
    c = { 'Item 2. 1%w', 'Item 22 2a' }
    m = Matcher c
    assert.same { 'Item 2. 1%w' }, m('%w')
