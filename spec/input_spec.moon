import Spy from vilu.spec
input = vilu.input

describe 'Input', ->

  describe 'translate_key(event)', ->

    context 'for ordinary characters', ->
      it 'returns a table with the character, key name and key code string', ->
        tr = input.translate_key character: 'A', key_name: 'A', key_code: 65
        assert_table_equal tr, { 'A', 'A', '65' }

    context 'when character is missing', ->
      it 'returns a table with key name and key code string', ->
        tr = input.translate_key key_name: 'down', key_code: 123
        assert_table_equal tr, { 'down', '123' }

    context 'when only the code is available', ->
      it 'returns a table with the key code string', ->
        tr = input.translate_key key_code: 123
        assert_table_equal tr, { '123' }

    context 'with modifiers', ->
      it 'prepends a modifier string representation to all translations for ctrl and alt', ->
        tr = input.translate_key
          character: 'a', key_name: 'a', key_code: 123,
          control: true, alt: true
        mods = 'ctrl+alt+'
        assert_table_equal tr, { mods .. 'a', mods .. 'a', mods .. '123' }

      it 'emits the shift modifier if the character is known', ->
        tr = input.translate_key
          character: 'A', key_name: 'a', key_code: 123,
          control: true, shift: true
        assert_table_equal tr, { 'ctrl+A', 'ctrl+shift+a', 'ctrl+shift+123' }

  describe 'process(view, buffer, event)', ->

    context 'when looking up handlers', ->

      it 'tries each translated key in order for a given keymap', ->
        buffer = keymap: Spy!
        input.process {}, buffer, character: 'A', key_name: 'A', key_code: 65
        assert_table_equal buffer.keymap.reads, { 'A', 'A', '65' }

      it 'searches the buffer keymap -> the mode keymap -> global keymap', ->
        key_args = character: 'A', key_name: 'A', key_code: 65
        buffer_map = Spy!
        mode_map = Spy!
        input.keymap = Spy!

        buffer =
          keymap: buffer_map
          mode:
            keymap: mode_map

        input.process {}, buffer, key_args
        assert_equal #input.keymap.reads, 3
        assert_table_equal input.keymap.reads, mode_map.reads
        assert_table_equal mode_map.reads, buffer_map.reads

      it 'skips any keymaps not present', ->
        key_args = character: 'A', key_name: 'A', key_code: 65
        input.keymap = Spy!

        buffer = {}
        assert_true (pcall input.process, {}, buffer, key_args)
        assert_equal #input.keymap.reads, 3

    context 'when invoking handlers', ->
      it 'passes the view and buffer as arguments', ->
        received = {}
        buffer = keymap: { k: (...) -> received = {...} }
        view = {}
        input.process view, buffer, character: 'k', key_code: 65
        assert_table_equal received, { view, buffer }

      it 'returns early with true unless a handler explicitly returns false', ->
        mode_handler = Spy!
        buffer =
          keymap: { k: -> nil }
          mode:
            keymap:
              k: mode_handler
        assert_true input.process({}, buffer, character: 'k', key_code: 65)
        assert_false mode_handler.called

        buffer.keymap.k = -> false
        assert_true input.process({}, buffer, character: 'k', key_code: 65)
        assert_true mode_handler.called

      it 'returns true if a handler raises an error', ->
        buffer = keymap: { k: -> error 'BOOM!' }
        assert_true input.process {}, buffer, character: 'k', key_code: 65

      it 'returns false if no handlers are found', ->
        assert_false input.process {}, {}, character: 'k', key_code: 65

      it 'signals an error if a handler raises an error', true
