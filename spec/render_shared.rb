require_relative 'spec_helper'

require_relative '../lib/hiptest-publisher'
require_relative '../lib/hiptest-publisher/datatable_fixer'
require_relative '../lib/hiptest-publisher/gherkin_adder'
require_relative '../lib/hiptest-publisher/parameter_type_adder'
require_relative '../lib/hiptest-publisher/nodes'
require_relative '../lib/hiptest-publisher/options_parser'


shared_context "shared render" do

  include HelperFactories

  before(:each) do
    @null = Hiptest::Nodes::NullLiteral.new
    @what_is_your_quest = Hiptest::Nodes::StringLiteral.new("What is your quest ?")
    @fighters = Hiptest::Nodes::StringLiteral.new('fighters')
    @pi = Hiptest::Nodes::NumericLiteral.new('3.14')
    @false = Hiptest::Nodes::BooleanLiteral.new(false)
    @true = Hiptest::Nodes::BooleanLiteral.new(true)
    @foo_variable = Hiptest::Nodes::Variable.new('foo')
    @foo_bar_variable = Hiptest::Nodes::Variable.new('foo bar')
    @x_variable = Hiptest::Nodes::Variable.new('x')

    @foo_symbol = Hiptest::Nodes::Symbol.new('foo', '')
    @foo_fighters_symbol = Hiptest::Nodes::Symbol.new('foo(fighters)', '"')

    # Except for Ruby, they will be rendered as it.
    @foo_symbol_rendered = 'foo'
    @foo_fighters_symbol_rendered = 'foo(fighters)'

    @foo_fighters_prop = Hiptest::Nodes::Property.new(@foo_variable, @fighters)
    @foo_dot_fighters = Hiptest::Nodes::Field.new(@foo_variable, 'fighters')
    @foo_brackets_fighters = Hiptest::Nodes::Index.new(@foo_variable, @fighters)
    @foo_minus_fighters = Hiptest::Nodes::BinaryExpression.new(@foo_variable, '-', @fighters)
    @minus_foo = Hiptest::Nodes::UnaryExpression.new('-', @foo_variable)
    @parenthesis_foo = Hiptest::Nodes::Parenthesis.new(@foo_variable)

    @foo_list = Hiptest::Nodes::List.new([@foo_variable, @fighters])
    @foo_dict =  Hiptest::Nodes::Dict.new([@foo_fighters_prop,
      Hiptest::Nodes::Property.new('Alt', 'J')
    ])

    @simple_template = Hiptest::Nodes::Template.new([
      Hiptest::Nodes::StringLiteral.new('A simple template')
    ])

    @foo_template = Hiptest::Nodes::Template.new([@foo_variable, @fighters])
    @double_quotes_template = Hiptest::Nodes::Template.new([
      Hiptest::Nodes::StringLiteral.new('Fighters said "Foo !"')
    ])
    @empty_template = Hiptest::Nodes::Template.new([])

    @assign_fighters_to_foo = Hiptest::Nodes::Assign.new(@foo_variable, @fighters)
    @assign_foo_to_fighters = Hiptest::Nodes::Assign.new(
      Hiptest::Nodes::Variable.new('fighters'),
      Hiptest::Nodes::StringLiteral.new('foo'))
    @call_foo = Hiptest::Nodes::Call.new('foo')
    @call_foo_bar = Hiptest::Nodes::Call.new('foo bar')
    @argument = Hiptest::Nodes::Argument.new('x', @fighters)
    @call_foo_with_fighters = Hiptest::Nodes::Call.new('foo', [@argument])
    @call_foo_bar_with_fighters = Hiptest::Nodes::Call.new('foo bar', [@argument])
    @call_with_special_characters_in_value = Hiptest::Nodes::Call.new('my call with weird arguments', [
      Hiptest::Nodes::Argument.new('__free_text', Hiptest::Nodes::Template.new([
        Hiptest::Nodes::StringLiteral.new([
          "{",
          "  this: 'is',",
          "  some: ['JSON', 'outputed'],",
          "  as: 'a string'",
          "}"
        ].join("\n"))
      ]))
    ])

    @simple_tag = Hiptest::Nodes::Tag.new('myTag')
    @valued_tag = Hiptest::Nodes::Tag.new('myTag', 'somevalue')

    @plic_param = Hiptest::Nodes::Parameter.new('plic')
    @x_param = Hiptest::Nodes::Parameter.new('x')
    @plic_param_default_ploc = Hiptest::Nodes::Parameter.new(
      'plic',
      Hiptest::Nodes::StringLiteral.new('ploc'))
    @flip_param_default_flap = Hiptest::Nodes::Parameter.new(
      'flip',
      Hiptest::Nodes::StringLiteral.new('flap'))

    @action_foo_fighters = Hiptest::Nodes::Step.new('action', @foo_template)

    @if_then = Hiptest::Nodes::IfThen.new(@true, [@assign_fighters_to_foo])
    @if_then_else = Hiptest::Nodes::IfThen.new(
      @true, [@assign_fighters_to_foo], [@assign_foo_to_fighters])
    @while_loop = Hiptest::Nodes::While.new(
      @foo_variable,
      [
        @assign_foo_to_fighters,
        @call_foo_with_fighters
      ])

    @empty_action_word = Hiptest::Nodes::Actionword.new('my action word')
    @tagged_action_word = Hiptest::Nodes::Actionword.new(
      'my action word',
      [@simple_tag, @valued_tag])

    @described_action_word = Hiptest::Nodes::Actionword.new(
      'my action word',
      [],
      [],
      [],
      '1234',
      'Some description')

    @parameterized_action_word = Hiptest::Nodes::Actionword.new(
      'my action word',
      [],
      [@plic_param, @flip_param_default_flap])

    full_body = [
      Hiptest::Nodes::Assign.new(@foo_variable, @pi),
      Hiptest::Nodes::IfThen.new(
        Hiptest::Nodes::BinaryExpression.new(
          @foo_variable,
          '>',
          @x_variable),
        [
          Hiptest::Nodes::Step.new('result', "x is greater than Pi")
        ],
        [
          Hiptest::Nodes::Step.new('result', "x is lower than Pi\non two lines")
        ])
      ]

    @full_actionword = Hiptest::Nodes::Actionword.new(
      'compare to pi',
      [@simple_tag],
      [@x_param],
      full_body)

    @step_action_word = Hiptest::Nodes::Actionword.new(
      'my action word',
      [],
      [],
      [Hiptest::Nodes::Step.new('action', "basic action")])

    @full_scenario = Hiptest::Nodes::Scenario.new(
      'compare to pi',
       "This is a scenario which description \nis on two lines",
      [@simple_tag],
      [@x_param],
      full_body)
    @full_scenario.parent = Hiptest::Nodes::Scenarios.new([])
    @full_scenario.parent.parent = Hiptest::Nodes::Project.new("Mike's project")


    @dataset1 = Hiptest::Nodes::Dataset.new('Wrong \'login\'', [
      Hiptest::Nodes::Argument.new('login', Hiptest::Nodes::StringLiteral.new('invalid')),
      Hiptest::Nodes::Argument.new('password', Hiptest::Nodes::StringLiteral.new('invalid')),
      Hiptest::Nodes::Argument.new('expected', Hiptest::Nodes::StringLiteral.new('Invalid username or password'))
    ])

    @dataset2 = Hiptest::Nodes::Dataset.new('Wrong "password"', [
      Hiptest::Nodes::Argument.new('login', Hiptest::Nodes::StringLiteral.new('valid')),
      Hiptest::Nodes::Argument.new('password', Hiptest::Nodes::StringLiteral.new('invalid')),
      Hiptest::Nodes::Argument.new('expected', Hiptest::Nodes::StringLiteral.new('Invalid username or password'))
    ])

    @dataset3 = Hiptest::Nodes::Dataset.new('Valid \'login\'/"password"', [
      Hiptest::Nodes::Argument.new('login', Hiptest::Nodes::StringLiteral.new('valid')),
      Hiptest::Nodes::Argument.new('password', Hiptest::Nodes::StringLiteral.new('valid')),
      Hiptest::Nodes::Argument.new('expected', Hiptest::Nodes::NullLiteral.new())
    ])
    @datatable = Hiptest::Nodes::Datatable.new([@dataset1, @dataset2, @dataset3])
    [@dataset1, @dataset2, @dataset3].each {|dt| dt.parent = @datatable }

    @scenario_with_datatable = Hiptest::Nodes::Scenario.new(
      'check login',
      "Ensure the login process",
      [],
      [
        Hiptest::Nodes::Parameter.new('login'),
        Hiptest::Nodes::Parameter.new('password'),
        Hiptest::Nodes::Parameter.new('expected')
      ],
      [
        Hiptest::Nodes::Call.new('fill login', [
          Hiptest::Nodes::Argument.new('login', Hiptest::Nodes::Variable.new('login')),
        ]),
        Hiptest::Nodes::Call.new('fill password', [
          Hiptest::Nodes::Argument.new('password', Hiptest::Nodes::Variable.new('password')),
        ]),
        Hiptest::Nodes::Call.new('press enter'),
        Hiptest::Nodes::Call.new('assert "error" is displayed', [
          Hiptest::Nodes::Argument.new('error', Hiptest::Nodes::Variable.new('expected')),
        ])
      ],
      nil,
      @datatable)
    @datatable.parent = @scenario_with_datatable
    @scenario_with_datatable.parent = Hiptest::Nodes::Scenarios.new([])
    @scenario_with_datatable.parent.parent = Hiptest::Nodes::Project.new('A project with datatables')

    @actionwords = Hiptest::Nodes::Actionwords.new([
      Hiptest::Nodes::Actionword.new('first action word'),
      Hiptest::Nodes::Actionword.new(
        'second action word', [], [], [
          Hiptest::Nodes::Call.new('first action word')
        ])
    ])

    @scenarios = Hiptest::Nodes::Scenarios.new([
      Hiptest::Nodes::Scenario.new('first scenario'),
      Hiptest::Nodes::Scenario.new(
        'second scenario', '', [], [], [
          Hiptest::Nodes::Call.new('my action word')
        ])
    ])
    @scenarios.parent = Hiptest::Nodes::Project.new("Mike's project")

    @actionwords_with_parameters = Hiptest::Nodes::Actionwords.new([
      Hiptest::Nodes::Actionword.new('aw with int param', [], [Hiptest::Nodes::Parameter.new('x')], []),
      Hiptest::Nodes::Actionword.new('aw with float param', [], [Hiptest::Nodes::Parameter.new('x')], []),
      Hiptest::Nodes::Actionword.new('aw with boolean param', [], [Hiptest::Nodes::Parameter.new('x')], []),
      Hiptest::Nodes::Actionword.new('aw with null param', [], [Hiptest::Nodes::Parameter.new('x')], []),
      Hiptest::Nodes::Actionword.new('aw with string param', [], [Hiptest::Nodes::Parameter.new('x')], []),
      Hiptest::Nodes::Actionword.new('aw with template param', [], [Hiptest::Nodes::Parameter.new('x')], [])
    ])

    @scenarios_with_many_calls = Hiptest::Nodes::Scenarios.new([
      Hiptest::Nodes::Scenario.new('many calls scenarios', '', [], [], [
        Hiptest::Nodes::Call.new('aw with int param', [
          Hiptest::Nodes::Argument.new('x', Hiptest::Nodes::NumericLiteral.new('3'))]),
        Hiptest::Nodes::Call.new('aw with float param', [
          Hiptest::Nodes::Argument.new('x',
            Hiptest::Nodes::NumericLiteral.new('4.2')
          )]),
        Hiptest::Nodes::Call.new('aw with boolean param', [
          Hiptest::Nodes::Argument.new('x',
            Hiptest::Nodes::BooleanLiteral.new(true)
          )]),
        Hiptest::Nodes::Call.new('aw_with_null_param', [
          Hiptest::Nodes::Argument.new('x',
            Hiptest::Nodes::NullLiteral.new
          )]),
        Hiptest::Nodes::Call.new('aw with string param', [
          Hiptest::Nodes::Argument.new('x', Hiptest::Nodes::StringLiteral.new('toto'))]),
        Hiptest::Nodes::Call.new('aw with string param', [
          Hiptest::Nodes::Argument.new('x', Hiptest::Nodes::Template.new(Hiptest::Nodes::StringLiteral.new('toto')))])
      ])])

    @project = Hiptest::Nodes::Project.new("Mike's project", "", nil, @scenarios_with_many_calls, @actionwords_with_parameters)

    @first_test = Hiptest::Nodes::Test.new(
      'Login',
      "The description is on \ntwo lines",
      [@simple_tag, @valued_tag],
      [
        Hiptest::Nodes::Call.new('visit', [
          Hiptest::Nodes::Argument.new('url', Hiptest::Nodes::StringLiteral.new('/login'))
        ]),
        Hiptest::Nodes::Call.new('fill', [
          Hiptest::Nodes::Argument.new('login', Hiptest::Nodes::StringLiteral.new('user@example.com'))
        ]),
        Hiptest::Nodes::Call.new('fill', [
          Hiptest::Nodes::Argument.new('password', Hiptest::Nodes::StringLiteral.new('s3cret'))
        ]),
        Hiptest::Nodes::Call.new('click', [
          Hiptest::Nodes::Argument.new('path', Hiptest::Nodes::StringLiteral.new('.login-form input[type=submit]'))
        ]),
        Hiptest::Nodes::Call.new('checkUrl', [
          Hiptest::Nodes::Argument.new('path', Hiptest::Nodes::StringLiteral.new('/welcome')
        )])
      ])

    @second_test = Hiptest::Nodes::Test.new(
      'Failed login',
      '',
      [@valued_tag],
      [
        Hiptest::Nodes::Call.new('visit', [
          Hiptest::Nodes::Argument.new('url', Hiptest::Nodes::StringLiteral.new('/login'))
        ]),
        Hiptest::Nodes::Call.new('fill', [
          Hiptest::Nodes::Argument.new('login', Hiptest::Nodes::StringLiteral.new('user@example.com'))
        ]),
        Hiptest::Nodes::Call.new('fill', [
          Hiptest::Nodes::Argument.new('password', Hiptest::Nodes::StringLiteral.new('notTh4tS3cret'))
        ]),
        Hiptest::Nodes::Call.new('click', [
          Hiptest::Nodes::Argument.new('path', Hiptest::Nodes::StringLiteral.new('.login-form input[type=submit]'))
        ]),
        Hiptest::Nodes::Call.new('checkUrl', [
          Hiptest::Nodes::Argument.new('path', Hiptest::Nodes::StringLiteral.new('/login')
        )])
      ])

    @tests = Hiptest::Nodes::Tests.new([@first_test, @second_test])
    @first_test.parent = @tests
    @second_test.parent = @tests
    @tests.parent = Hiptest::Nodes::Project.new("Mike's test project")


    @folders_project = Hiptest::Nodes::Project.new("Folder's project")
    @root_folder = make_folder("My root folder", parent: @folders_project.children[:test_plan])
    @first_root_scenario = make_scenario("One root scenario", folder: @root_folder)
    @second_root_scenario = make_scenario("Another root scenario", folder: @root_folder)
    @child_folder = make_folder("child folder", parent: @root_folder)
    @grand_child_folder = make_folder("A grand-child folder", parent: @child_folder)
    @second_grand_child_folder = make_folder("A second grand-child folder", parent: @child_folder, body: [
      Hiptest::Nodes::Call.new('visit', [
        Hiptest::Nodes::Argument.new('url', Hiptest::Nodes::StringLiteral.new('/login'))
      ]),
      Hiptest::Nodes::Call.new('fill', [
        Hiptest::Nodes::Argument.new('login', Hiptest::Nodes::StringLiteral.new('user@example.com'))
      ]),
      Hiptest::Nodes::Call.new('fill', [
        Hiptest::Nodes::Argument.new('password', Hiptest::Nodes::StringLiteral.new('notTh4tS3cret'))
      ])
    ])
    @grand_child_scenario = make_scenario("One grand'child scenario", folder: @second_grand_child_folder)
    @folders_project.children[:test_plan].organize_folders

    # In hiptest
    # scenario 'reset password' do
    #   call given 'Page "url" is opened'(url='/login')
    #   call when 'I click on "link"'(link='Reset password')
    #   call then 'page "url" should be opened'(url='/reset-password')
    # end
    @bdd_scenario = Hiptest::Nodes::Scenario.new(
      'Reset password',
      '',
      [],
      [],
      [
        Hiptest::Nodes::Call.new('Page "url" is opened', [
          Hiptest::Nodes::Argument.new('url', Hiptest::Nodes::StringLiteral.new('/login'))
        ], "given"),
        Hiptest::Nodes::Call.new('I click on "link"', [
          Hiptest::Nodes::Argument.new('link', Hiptest::Nodes::StringLiteral.new('Reset password'))
        ], "when"),
        Hiptest::Nodes::Call.new('Page "url" should be opened', [
          Hiptest::Nodes::Argument.new('url', Hiptest::Nodes::StringLiteral.new('/reset-password'))
        ], 'then')
      ])
    @bdd_project = Hiptest::Nodes::Project.new('My BDD project')
    @bdd_project.children[:actionwords] = Hiptest::Nodes::Actionwords.new([
      Hiptest::Nodes::Actionword.new('Page "url" is opened', [], [Hiptest::Nodes::Parameter.new('url')], []),
      Hiptest::Nodes::Actionword.new('I click on "link"', [], [Hiptest::Nodes::Parameter.new('link')], []),
      Hiptest::Nodes::Actionword.new('Page "url" should be opened', [], [Hiptest::Nodes::Parameter.new('url')], [])
    ])
    @bdd_project.children[:scenarios] = Hiptest::Nodes::Scenarios.new([@bdd_scenario])
    Hiptest::Nodes::ParentAdder.add(@bdd_project)
    Hiptest::GherkinAdder.add(@bdd_project)
  end

  def rendering(node)
    @context = context_for(
      node: node,
      # only to select the right config group: we render [actionwords], [tests] and others differently
      only: only,
      # in tests, simulate user options like --language, --framework,
      # --split-scenarios, --with-folders, package= or namespace= (in config file)
      language: language,
      framework: framework,
      split_scenarios: split_scenarios,
      with_folders: with_folders,
      namespace: namespace,
      package: package)
    node.render(@context)
  end
end

shared_examples "a renderer" do

  let(:split_scenarios) { nil }
  let(:with_folders) { nil }
  let(:package) { nil } # only used for Java
  let(:namespace) { nil } # only used for C#

  context "[tests] group" do
    let(:only) { 'tests' }

    it 'NullLiteral' do
      expect(rendering(@null)).to eq(@null_rendered)
    end

    it 'StringLiteral' do
      expect(rendering(@what_is_your_quest)).to eq(@what_is_your_quest_rendered)
    end

    it 'NumericLiteral' do
      expect(rendering(@pi)).to eq(@pi_rendered)
    end

    it 'BooleanLiteral' do
      expect(rendering(@false)).to eq(@false_rendered)
    end

    it 'Variable' do
      expect(rendering(@foo_variable)).to eq(@foo_variable_rendered)
    end

    it 'Symbols' do
      expect(rendering(@foo_symbol)).to eq(@foo_symbol_rendered)
      expect(rendering(@foo_fighters_symbol)).to eq(@foo_fighters_symbol_rendered)
    end

    it 'Property' do
      expect(rendering(@foo_fighters_prop)).to eq(@foo_fighters_prop_rendered)
    end

    it 'Field' do
      expect(rendering(@foo_dot_fighters)).to eq(@foo_dot_fighters_rendered)
    end

    it 'Index' do
      expect(rendering(@foo_brackets_fighters)).to eq(@foo_brackets_fighters_rendered)
    end

    it 'BinaryExpression' do
      expect(rendering(@foo_minus_fighters)).to eq(@foo_minus_fighters_rendered)
    end

    it 'UnaryExpression' do
      expect(rendering(@minus_foo)).to eq(@minus_foo_rendered)
    end

    it 'Parenthesis' do
      expect(rendering(@parenthesis_foo)).to eq(@parenthesis_foo_rendered)
    end

    it 'List' do
      expect(rendering(@foo_list)).to eq(@foo_list_rendered)
    end

    it 'Dict' do
      expect(rendering(@foo_dict)).to eq(@foo_dict_rendered)
    end

    it 'Template' do
      expect(rendering(@foo_template)).to eq(@foo_template_rendered)
      expect(rendering(@double_quotes_template)).to eq(@double_quotes_template_rendered)
      expect(rendering(@empty_template)).to eq(@empty_template_rendered)
    end

    it 'Assign' do
      expect(rendering(@assign_fighters_to_foo)).to eq(@assign_fighters_to_foo_rendered)
    end

    it 'Call' do
      expect(rendering(@call_foo)).to eq(@call_foo_rendered)
      expect(rendering(@call_foo_bar)).to eq(@call_foo_bar_rendered)
      expect(rendering(@call_foo_with_fighters)).to eq(@call_foo_with_fighters_rendered)
      expect(rendering(@call_foo_bar_with_fighters)).to eq(@call_foo_bar_with_fighters_rendered)
      expect(rendering(@call_with_special_characters_in_value)).to eq(@call_with_special_characters_in_value_rendered)
    end

    it 'IfThen' do
      expect(rendering(@if_then)).to eq(@if_then_rendered)
      expect(rendering(@if_then_else)).to eq(@if_then_else_rendered)
    end

    it "Step" do
      expect(rendering(@action_foo_fighters)).to eq(@action_foo_fighters_rendered)
    end

    it 'While' do
      expect(rendering(@while_loop)).to eq(@while_loop_rendered)
    end

    it 'Tag' do
      expect(rendering(@simple_tag)).to eq(@simple_tag_rendered)
      expect(rendering(@valued_tag)).to eq(@valued_tag_rendered)
    end

    it 'Parameter' do
      expect(rendering(@plic_param)).to eq(@plic_param_rendered)
      expect(rendering(@plic_param_default_ploc)).to eq(@plic_param_default_ploc_rendered)
    end

    context 'Actionword' do
      it 'empty' do
        expect(rendering(@empty_action_word)).to eq(@empty_action_word_rendered)
      end

      it 'with tags' do
        expect(rendering(@tagged_action_word)).to eq(@tagged_action_word_rendered)
      end

      it 'with description' do
        expect(rendering(@described_action_word)).to eq(@described_action_word_rendered)
      end

      it 'with parameters' do
        expect(rendering(@parameterized_action_word)).to eq(@parameterized_action_word_rendered)
      end

      it 'with body' do
        expect(rendering(@full_actionword)).to eq(@full_actionword_rendered)
      end

      it 'with body that contains only step' do
        expect(rendering(@step_action_word)).to eq(@step_action_word_rendered)
      end
    end

    context 'Scenario' do
      it 'can be rendered to be inserted in the scenarios list' do
        expect(rendering(@full_scenario)).to eq(@full_scenario_rendered)
      end

      context 'with splitted files' do
        let(:split_scenarios) { true }

        it 'can also be rendered so it will be in a single file' do
          expect(rendering(@full_scenario)).to eq(@full_scenario_rendered_for_single_file)
        end
      end

      it 'can be rendered with its datatable' do
        expect(rendering(@scenario_with_datatable)).to eq(@scenario_with_datatable_rendered)
      end

      context 'with splitted files' do
        let(:split_scenarios) { true }

        it 'can be rendered with its datatable in a single file' do
          expect(rendering(@scenario_with_datatable)).to eq(@scenario_with_datatable_rendered_in_single_file)
        end
      end

      it 'the UID is displayed in the name if set' do
        @full_scenario.set_uid('abcd-1234')
        expect(rendering(@full_scenario)).to eq(@full_scenario_with_uid_rendered)
      end

      it 'when the uid is set at the dataset level, it is rendered in the dataset export name' do
        uids = ['a-123', 'b-456', 'c-789']
        @scenario_with_datatable.children[:datatable].children[:datasets].each_with_index do |dataset, index|
          dataset.set_uid(uids[index])
        end

        expect(rendering(@scenario_with_datatable)).to eq(
          @scenario_with_datatable_rendered_with_uids)
      end

      it 'shows BDD annotations when present' do
        expect(rendering(@bdd_scenario)).to eq(@bdd_scenario_rendered)
      end
    end


    it 'Scenarios' do
      expect(rendering(@scenarios)).to eq(@scenarios_rendered)
    end

    context 'Test' do
      it 'can be rendered to be inserted in the tests list' do
        expect(rendering(@first_test)).to eq(@first_test_rendered)
      end

      context 'with splitted files' do
        let(:split_scenarios) { true }

        it 'can also be rendered so it will be in a single file' do
          expect(rendering(@first_test)).to eq(@first_test_rendered_for_single_file)
        end
      end
    end

    it 'Tests' do
      expect(rendering(@tests)).to eq(@tests_rendered)
    end

    context 'with folders' do
      let(:with_folders) { true }

      context 'Scenarios' do
        context 'with splitted files' do
          let(:split_scenarios) { true }

          it 'is rendered in a single file' do
            expect(rendering(@grand_child_scenario)).to eq(@grand_child_scenario_rendered_for_single_file)
          end
        end
      end

      context 'Folders' do
        let(:split_scenarios) { false }

        it 'renders all scenarios in a single file' do
          expect(rendering(@root_folder)).to eq(@root_folder_rendered)
        end

        it 'adapts path to load actionword file correctly' do
          expect(rendering(@grand_child_folder)).to eq(@grand_child_folder_rendered)
        end

        it 'exports the definition as a setup/before/whatever it is called' do
          expect(rendering(@second_grand_child_folder)).to eq(@second_grand_child_folder_rendered)
        end
      end
    end
  end

  context '[actionwords] group' do
    let(:only) { "actionwords" }

    it 'Actionwords' do
      expect(rendering(@actionwords)).to eq(@actionwords_rendered)
    end

    it 'Actionwords with parameters of different types' do
      Hiptest::Nodes::ParameterTypeAdder.add(@project)
      expect(rendering(@project.children[:actionwords])).to eq(@actionwords_with_params_rendered)
    end
  end
end

shared_examples "a BDD renderer" do

  include HelperFactories

  # Note: we do not want to test everything as we'll only render
  # tests and calls.
  # You have to define language and framework.
  let(:language) {nil}
  let(:framework) {nil}

  let(:root_folder) { make_folder("Colors") }
  let(:warm_colors_folder) { make_folder("Warm colors", parent: root_folder) }
  let(:cool_colors_folder) { make_folder("Cool colors", parent: root_folder, description: "Cool colors calm and relax.\nThey are the hues from blue green through blue violet, most grays included.") }
  let(:other_colors_folder) {
    make_folder("Other colors", parent: root_folder, body: [
      make_call("I have colors to mix",  annotation: "given"),
      make_call("I know the expected color",  annotation: "and"),
    ])
  }
  let(:regression_folder) {
    make_folder("Regression tests", parent: root_folder)
  }
  let(:gherkin_special_arguments_folder) {
    make_folder('Gherkin special arguments', parent: root_folder)
  }

  let(:actionwords) {
    [
      make_actionword("the color \"color\"", parameters: [make_parameter("color")]),
      make_actionword("you mix colors"),
      make_actionword("you obtain \"color\"", parameters: [make_parameter("color")]),
      make_actionword("unused action word"),
      make_actionword("you cannot play croquet"),
      make_actionword("I am on the \"site\" home page", parameters: [make_parameter("site"), make_parameter("__free_text", default: literal(""))])
    ]
  }

  let(:create_white_test) {
    make_test("Create white", body: [
      make_call("the color \"color\"",  annotation: "given", arguments: [make_argument("color", template_of_literals("blue"))]),
      make_call("the color \"color\"",  annotation:   "and", arguments: [make_argument("color", template_of_literals("red"))]),
      make_call("the color \"color\"",  annotation:   "and", arguments: [make_argument("color", template_of_literals("green"))]),
      make_call("you mix colors",       annotation:  "when"),
      make_call("you obtain \"color\"", annotation:  "then", arguments: [make_argument("color", template_of_literals("white"))])
    ])
  }

  let(:create_green_scenario) {
    make_scenario("Create green",
      folder: cool_colors_folder,
      body: [
        make_call("the color \"color\"",  annotation: "given", arguments: [make_argument("color", template_of_literals("blue"))]),
        make_call("the color \"color\"",  annotation: "and", arguments: [make_argument("color", template_of_literals("yellow"))]),
        make_call("you mix colors",       annotation: "when"),
        make_call("you obtain \"color\"", annotation: "then", arguments: [make_argument("color", template_of_literals("green"))]),
        make_call("you cannot play croquet", annotation:  "but", arguments: []),
      ])
  }

  let(:create_purple_scenario) {
    make_scenario("Create purple",
      folder: cool_colors_folder,
      body: [
        make_call("the color \"color\"",  annotation: "given", arguments: [make_argument("color", template_of_literals("blue"))]),
        make_call("the color \"color\"",  annotation: "and", arguments: [make_argument("color", template_of_literals("red"))]),
        make_call("you mix colors",       annotation: "when"),
        make_call("you obtain \"color\"", annotation: "then", arguments: [make_argument("color", template_of_literals("purple"))]),
      ])
  }

  let(:unannotated_create_orange_scenario) {
    make_scenario("Create orange",
      folder: warm_colors_folder,
      body: [
        make_call("the color \"color\"", arguments: [make_argument("color", template_of_literals("red"))]),
        make_call("the color \"color\"", arguments: [make_argument("color", template_of_literals("yellow"))]),
        make_call("you mix colors"),
        make_call("you obtain \"color\"", arguments: [make_argument("color", template_of_literals("orange"))])
      ])
  }

  let(:create_secondary_colors_scenario) {
    make_scenario("Create secondary colors",
      folder: other_colors_folder,
      parameters: [
        make_parameter("first_color"),
        make_parameter("second_color"),
        make_parameter("got_color"),
      ],
      body: [
        make_call("the color \"color\"",  annotation: "given", arguments: [make_argument("color", variable("first_color"))]),
        make_call("the color \"color\"",  annotation: "and", arguments: [make_argument("color", variable("second_color"))]),
        make_call("you mix colors",       annotation: "when"),
        make_call("you obtain \"color\"", annotation: "then", arguments: [make_argument("color", variable("got_color"))]),
      ],
      datatable: Hiptest::Nodes::Datatable.new([
        Hiptest::Nodes::Dataset.new("Mix to green", [
          make_argument("first_color", template_of_literals("blue")),
          make_argument("second_color", template_of_literals("yellow")),
          make_argument("got_color", template_of_literals("green")),
        ]),
        Hiptest::Nodes::Dataset.new("Mix to orange", [
          make_argument("first_color", template_of_literals("yellow")),
          make_argument("second_color", template_of_literals("red")),
          make_argument("got_color", template_of_literals("orange")),
        ]),
        Hiptest::Nodes::Dataset.new("Mix to purple", [
          make_argument("first_color", literal("red")),
          make_argument("second_color", literal("blue")),
          make_argument("got_color", literal("purple")),
        ]),
      ]))
  }

  let(:scenario_with_capital_parameters) {
    make_scenario("Validate Nav",
      folder: regression_folder,
      parameters: [make_parameter("SITE_NAME")],
      body: [
        make_call("I am on the \"site\" home page",  annotation: "given", arguments: [make_argument("site", variable("SITE_NAME"))])
      ],
      datatable: Hiptest::Nodes::Datatable.new([
        Hiptest::Nodes::Dataset.new("Open Google", [
          make_argument("SITE_NAME", template_of_literals("http://google.com"))
        ])
      ]))
  }

  let(:scenario_with_incomplete_datatable) {
    make_scenario("Incomplete datatable",
      folder: regression_folder,
      parameters: [
        make_parameter("first_color"),
        make_parameter("second_color"),
        make_parameter("got_color"),
      ],
      body: [
        make_call("the color \"color\"",  annotation: "given", arguments: [make_argument("color", variable("first_color"))]),
        make_call("the color \"color\"",  annotation: "and", arguments: [make_argument("color", variable("second_color"))]),
        make_call("you mix colors",       annotation: "when"),
        make_call("you obtain \"color\"", annotation: "then", arguments: [make_argument("color", variable("got_color"))]),
      ],
      datatable: Hiptest::Nodes::Datatable.new([
        Hiptest::Nodes::Dataset.new("Mix to green", [
          make_argument("first_color", template_of_literals("blue")),
          make_argument("second_color", template_of_literals("yellow")),
          make_argument("got_color", template_of_literals("green")),
        ]),
        Hiptest::Nodes::Dataset.new("Mix to orange", [
          make_argument("first_color", template_of_literals("yellow")),
          make_argument("second_color", template_of_literals("red"))
        ]),
        Hiptest::Nodes::Dataset.new("Mix to purple", [
          make_argument("first_color", literal("red"))
        ]),
      ]))
  }

  let(:scenario_with_freetext_argument) {
    make_scenario("Open a site with comments",
      folder: gherkin_special_arguments_folder,
      parameters: [],
      body: [
        make_call("I am on the \"site\" home page", annotation: "when", arguments: [
          make_argument('site', template_of_literals("http://google.com")),
          make_argument('__free_text', template_of_literals([
            "Some explanations when opening the site:",
            " - for example one explanation",
            " - and another one"
          ].join("\n")))
        ]),
        make_call("stuff happens", annotation: 'then')
      ])
  }

  let!(:project) {
    make_project("Colors",
      scenarios: [create_green_scenario, create_secondary_colors_scenario, unannotated_create_orange_scenario, create_purple_scenario, scenario_with_capital_parameters, scenario_with_freetext_argument, scenario_with_incomplete_datatable],
      tests: [create_white_test],
      actionwords: actionwords,
      folders: [root_folder, warm_colors_folder, cool_colors_folder, other_colors_folder],
    ).tap do |p|
      Hiptest::Nodes::DatatableFixer.add(p)
      Hiptest::Nodes::ParentAdder.add(p)
      Hiptest::GherkinAdder.add(p)
    end
  }

  let(:options) {
    context_for(
      only: "features",
      language: language,
      framework: framework
    )
  }

  subject(:rendered) { node_to_render.render(options) }

  context 'Argument with a nil value' do
    let(:node_to_render) { make_argument("first_color", nil) }

    it 'renders as empty string' do
      expect(rendered).to eq('')
    end
  end

  context 'Test' do
    let(:node_to_render) { create_white_test }

    it 'generates a feature file' do
      expect(rendered).to eq([
        "Scenario: Create white",
        "  Given the color \"blue\"",
        "  And the color \"red\"",
        "  And the color \"green\"",
        "  When you mix colors",
        "  Then you obtain \"white\"",
        "",
      ].join("\n"))
    end
  end

  context 'Scenario' do
    let(:node_to_render) { scenario }
    let(:scenario) { create_green_scenario }

    it 'generates a feature file' do
      expect(rendered).to eq([
        "",
        "Scenario: Create green",
        "  Given the color \"blue\"",
        "  And the color \"yellow\"",
        "  When you mix colors",
        "  Then you obtain \"green\"",
        "  But you cannot play croquet",
        "",
      ].join("\n"))
    end

    it 'appends the UID if known' do
      scenario.children[:uid] = '1234-4567'

      expect(rendered).to eq([
        "",
        "Scenario: Create green (uid:1234-4567)",
        "  Given the color \"blue\"",
        "  And the color \"yellow\"",
        "  When you mix colors",
        "  Then you obtain \"green\"",
        "  But you cannot play croquet",
        "",
      ].join("\n"))
    end

    context 'without annotated calls' do
      let(:scenario) { unannotated_create_orange_scenario }

      it 'generates a feature file with bullet points steps' do
        expect(rendered).to eq([
          "",
          "Scenario: Create orange",
          "  * the color \"red\"",
          "  * the color \"yellow\"",
          "  * you mix colors",
          "  * you obtain \"orange\"",
          "",
        ].join("\n"))
      end
    end

    context 'with datatable' do
      let(:scenario) { create_secondary_colors_scenario }

      it 'generates a feature file with an Examples section' do
        expect(rendered).to eq([
          "",
          "Scenario Outline: Create secondary colors",
          "  Given the color \"<first_color>\"",
          "  And the color \"<second_color>\"",
          "  When you mix colors",
          "  Then you obtain \"<got_color>\"",
          "",
          "  Examples:",
          "    | first_color | second_color | got_color | hiptest-uid |",
          "    | blue | yellow | green |  |",
          "    | yellow | red | orange |  |",
          "    | red | blue | purple |  |",
          "",
        ].join("\n"))
      end

      it 'adds dataset UID as parameters if set (so they appear in output)' do
        scenario.children[:uid] = 'abcd-efgh'
        datasets = scenario.children[:datatable].children[:datasets]
        datasets.first.children[:uid] = '1234'
        datasets.last.children[:uid] = '5678'

        expect(rendered).to eq([
          "",
          "Scenario Outline: Create secondary colors (uid:abcd-efgh)",
          "  Given the color \"<first_color>\"",
          "  And the color \"<second_color>\"",
          "  When you mix colors",
          "  Then you obtain \"<got_color>\"",
          "",
          "  Examples:",
          "    | first_color | second_color | got_color | hiptest-uid |",
          "    | blue | yellow | green | uid:1234 |",
          "    | yellow | red | orange |  |",
          "    | red | blue | purple | uid:5678 |",
          "",
        ].join("\n"))
      end
    end

    context 'Gherkin special characters' do
      context 'DocString' do
        let(:scenario) {scenario_with_freetext_argument}

        it "is rendered when the argument is called '__free_text'" do
          expect(rendered).to eq([
            '',
            'Scenario: Open a site with comments',
            '  When I am on the "http://google.com" home page',
            '  """',
            "  Some explanations when opening the site:",
            "   - for example one explanation",
            "   - and another one",
            '  """',
            '  Then stuff happens',
            ''
          ].join("\n"))
        end
      end
    end

    context 'Regression tests:' do
      context 'when a scenario parameter is capitalized'
        let(:scenario) {scenario_with_capital_parameters}

        it 'the capitals are also keeps in the datatable headers' do
          expect(rendered).to eq([
            '',
            'Scenario Outline: Validate Nav',
            '  Given I am on the "<SITE_NAME>" home page',
            '',
            '  Examples:',
            '    | SITE_NAME | hiptest-uid |',
            '    | http://google.com |  |',
            ''
          ].join("\n"))
        end

      context 'when some datatable rows are incomplete' do
        # That one is a bit weird, but we found some examples where the XML
        # made by Hiptedt misses some data ...

        let(:scenario) {scenario_with_incomplete_datatable}

        it 'even if a data is missing, that is fixed during export' do
          expect(rendered).to eq([
            '',
            'Scenario Outline: Incomplete datatable',
            '  Given the color "<first_color>"',
            '  And the color "<second_color>"',
            '  When you mix colors',
            '  Then you obtain "<got_color>"',
            '',
            '  Examples:',
            '    | first_color | second_color | got_color | hiptest-uid |',
            '    | blue | yellow | green |  |',
            '    | yellow | red |  |  |',
            '    | red |  |  |  |',
            ''
          ].join("\n"))
        end
      end
    end

    context 'option no-uid' do
      let(:options) {
        context_for(
          only: "features",
          language: language,
          framework: framework,
          no_uids: true
        )
      }

      let(:scenario) { create_secondary_colors_scenario }


      it 'does not export the hiptest-uid column, nor the scenario uid' do
        scenario.children[:uid] = 'abcd-efgh'
        datasets = scenario.children[:datatable].children[:datasets]
        datasets.first.children[:uid] = '1234'
        datasets.last.children[:uid] = '5678'

        expect(rendered).to eq([
          "",
          "Scenario Outline: Create secondary colors",
          "  Given the color \"<first_color>\"",
          "  And the color \"<second_color>\"",
          "  When you mix colors",
          "  Then you obtain \"<got_color>\"",
          "",
          "  Examples:",
          "    | first_color | second_color | got_color |",
          "    | blue | yellow | green |",
          "    | yellow | red | orange |",
          "    | red | blue | purple |",
          "",
        ].join("\n"))
      end

      it 'also works when scenario has no datatable' do
        scenario.children[:uid] = 'abcd-efgh'
        scenario.children[:datatable].children[:datasets] = []

        expect(rendered).to eq([
          "",
          "Scenario: Create secondary colors",
          "  Given the color \"<first_color>\"",
          "  And the color \"<second_color>\"",
          "  When you mix colors",
          "  Then you obtain \"<got_color>\"",
          "",
        ].join("\n"))
      end
    end
  end

  context 'Folders' do
    let(:options) {
      context_for(
        only: "features",
        language: language,
        framework: framework
      )
    }

    let(:node_to_render) {
      other_colors_folder
    }

    it 'definition is exported as background' do
      expect(rendered).to eq([
        'Feature: Other colors',
        '',
        '',
        '  Background:',
        '    Given I have colors to mix',
        '    And I know the expected color',
        '',
        '  Scenario Outline: Create secondary colors',
        '    Given the color "<first_color>"',
        '    And the color "<second_color>"',
        '    When you mix colors',
        '    Then you obtain "<got_color>"',
        '',
        '    Examples:',
        '      | first_color | second_color | got_color | hiptest-uid |',
        '      | blue | yellow | green |  |',
        '      | yellow | red | orange |  |',
        '      | red | blue | purple |  |',
        ''
      ].join("\n"))
    end
  end

  context 'Tags are exported' do
    let(:simple_tag) {
      Hiptest::Nodes::Tag.new('myTag')
    }

    let(:valued_tag) {
      Hiptest::Nodes::Tag.new('myTag', 'some value')
    }

    let(:jira_tag) {
      Hiptest::Nodes::Tag.new('JIRA', 'CW-6')
    }

    let(:options) {
      context_for(
        only: "features",
        language: language,
        framework: framework
      )
    }

    context 'at feature level for' do
      let(:node_to_render) {
        cool_colors_folder
      }

      it 'Folder nodes' do
        node_to_render.children[:tags] = [simple_tag, valued_tag, jira_tag]

        expect(rendered).to eq([
          '@myTag @myTag-some_value @JIRA-CW-6',
          'Feature: Cool colors',
          '    Cool colors calm and relax.',
          '    They are the hues from blue green through blue violet, most grays included.',
          '',
          '  Scenario: Create green',
          '    Given the color "blue"',
          '    And the color "yellow"',
          '    When you mix colors',
          '    Then you obtain "green"',
          '    But you cannot play croquet',
          '',
          '  Scenario: Create purple',
          '    Given the color "blue"',
          '    And the color "red"',
          '    When you mix colors',
          '    Then you obtain "purple"',
          ''
        ].join("\n"))

      end
    end

    context 'at scenario level for' do
      let(:node_to_render) {
        cool_colors_folder.children[:scenarios].last
      }

      it 'Scenario tag' do
        node_to_render.children[:tags] = [simple_tag, valued_tag]

        expect(rendered).to eq([
          '',
          '@myTag @myTag-some_value',
          'Scenario: Create purple',
          '  Given the color "blue"',
          '  And the color "red"',
          '  When you mix colors',
          '  Then you obtain "purple"',
          ''
        ].join("\n"))
      end
    end
  end

  context 'Scenarios with split_scenarios = false' do
    let(:node_to_render) { project.children[:scenarios] }
    let(:options) {
      context_for(
        only: "features",
        language: language,
        framework: framework
      )
    }

    it 'generates a features.feature file asking to use --split-scenarios' do
      expect(rendered).to eq([
        "# To export your project to Gherkin correctly, please add the option",
        "# --split-scenarios when calling hiptest-publisher. It will generate one",
        "# feature file per folder from your project."
      ].join("\n"))
    end
  end

  context 'Actionwords as step definitions' do
    let(:options) {
      context_for(
        only: "step_definitions",
        language: language,
        framework: framework
      )
    }
    let(:node_to_render) { project.children[:actionwords] }

    it 'generates a steps definitions mapping' do
      expect(rendered).to eq(rendered_actionwords)
    end
  end
end
