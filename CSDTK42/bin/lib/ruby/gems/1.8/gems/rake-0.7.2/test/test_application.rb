#!/usr/bin/env ruby

begin
  require 'rubygems'
rescue LoadError
  # got no gems
end

require 'test/unit'
require 'rake'
require 'test/capture_stdout'
require 'flexmock'

TESTING_REQUIRE = [ ]

######################################################################
class TestApplication < Test::Unit::TestCase
  include CaptureStdout
  include FlexMock::TestCase

  def setup
    @app = Rake::Application.new
  end

  def test_constant_warning
    err = capture_stderr do @app.const_warning("Task") end
    assert_match(/warning/i, err)
    assert_match(/deprecated/i, err)
    assert_match(/Task/i, err)
  end

  def test_display_tasks
    @app.options.show_task_pattern = //
    @app.last_comment = "COMMENT"
    @app.define_task(Rake::Task, "t")
    out = capture_stdout do @app.display_tasks_and_comments end
    assert_match(/^rake t/, out)
    assert_match(/# COMMENT/, out)
  end

  def test_finding_rakefile
    assert @app.have_rakefile
    assert_equal "rakefile", @app.rakefile.downcase
  end

  def test_not_finding_rakefile
    @app.instance_eval { @rakefiles = ['NEVER_FOUND'] }
    assert ! @app.have_rakefile
    assert_nil @app.rakefile
  end

  def test_load_rakefile
    original_dir = Dir.pwd
    Dir.chdir("test/data/unittest")
    @app.handle_options
    @app.options.silent = true
    @app.load_rakefile
    assert_equal "rakefile", @app.rakefile.downcase
    assert_match(%r(unittest$), Dir.pwd)
  ensure
    Dir.chdir(original_dir)
  end

  def test_load_rakefile_from_subdir
    original_dir = Dir.pwd
    Dir.chdir("test/data/unittest/subdir")
    @app.handle_options
    @app.options.silent = true
    @app.load_rakefile
    assert_equal "rakefile", @app.rakefile.downcase
    assert_match(%r(unittest$), Dir.pwd)
  ensure
    Dir.chdir(original_dir)
  end

  def test_load_rakefile_not_found
    original_dir = Dir.pwd
    Dir.chdir("/")
    @app.handle_options
    @app.options.silent = true
    ex = assert_raise(RuntimeError) do @app.load_rakefile end
    assert_match(/no rakefile found/i, ex.message)
  ensure
    Dir.chdir(original_dir)
  end

  def test_not_caring_about_finding_rakefile
    @app.instance_eval { @rakefiles = [''] }
    assert @app.have_rakefile
    assert_equal '', @app.rakefile
  end

  def test_loading_imports
    mock = flexmock("loader")
    mock.should_receive(:load).with("x.dummy").once
    @app.add_loader("dummy", mock)
    @app.add_import("x.dummy")
    @app.load_imports
  end

  def test_building_imported_files_on_demand
    mock = flexmock("loader")
    mock.should_receive(:load).with("x.dummy").once
    mock.should_receive(:make_dummy).with_no_args.once
    @app.intern(Rake::Task, "x.dummy").enhance do mock.make_dummy end
    @app.add_loader("dummy", mock)
    @app.add_import("x.dummy")
    @app.load_imports
  end

  def test_good_run
    ran = false
    @app.options.silent = true
    @app.intern(Rake::Task, "default").enhance { ran = true }
    @app.run
    assert ran
  end

  def test_display_task_run
    ran = false
    ARGV.clear
    ARGV << '-f' << '-s' << '--tasks'
    @app.last_comment = "COMMENT"
    @app.define_task(Rake::Task, "default")
    out = capture_stdout { @app.run }
    assert @app.options.show_tasks
    assert ! ran
    assert_match(/rake default/, out)
    assert_match(/# COMMENT/, out)
  end

  def test_display_prereqs
    ran = false
    ARGV.clear
    ARGV << '-f' << '-s' << '--prereqs'
    @app.last_comment = "COMMENT"
    t = @app.define_task(Rake::Task, "default")
    t.enhance([:a, :b])
    @app.define_task(Rake::Task, "a")
    @app.define_task(Rake::Task, "b")
    out = capture_stdout { @app.run }
    assert @app.options.show_prereqs
    assert ! ran
    assert_match(/rake a$/, out)
    assert_match(/rake b$/, out)
    assert_match(/rake default\n( *(a|b)\n){2}/m, out)
  end

  def test_bad_run
    @app.intern(Rake::Task, "default").enhance { fail }
    ARGV.clear
    ARGV << '-f' << '-s'
    assert_raise(SystemExit) {
      err = capture_stderr { @app.run }
      assert_match(/see full trace/, err)
    }
  ensure
    ARGV.clear
  end

  def test_bad_run_with_trace
    @app.intern(Rake::Task, "default").enhance { fail }
    ARGV.clear
    ARGV << '-f' << '-s' << '-t'
    assert_raise(SystemExit) {
      err = capture_stderr { capture_stdout { @app.run } }
      assert_no_match(/see full trace/, err)
    }
  ensure
    ARGV.clear
  end

  def test_run_with_bad_options
    @app.intern(Rake::Task, "default").enhance { fail }
    ARGV.clear
    ARGV << '-f' << '-s' << '--xyzzy'
    assert_raise(SystemExit) {
      err = capture_stderr { capture_stdout { @app.run } }
    }
  ensure
    ARGV.clear
  end

end


######################################################################
class TestApplicationOptions < Test::Unit::TestCase
  include CaptureStdout

  def setup
    clear_argv
    RakeFileUtils.verbose_flag = false
    RakeFileUtils.nowrite_flag = false
  end

  def teardown
    clear_argv
    RakeFileUtils.verbose_flag = false
    RakeFileUtils.nowrite_flag = false
  end
  
  def clear_argv
    while ! ARGV.empty?
      ARGV.pop
    end
  end

  def test_default_options
    opts = command_line
    assert_nil opts.show_task_pattern
    assert_nil opts.dryrun
    assert_nil opts.trace
    assert_nil opts.nosearch
    assert_nil opts.silent
    assert_nil opts.show_prereqs
    assert_nil opts.show_tasks
    assert_nil opts.classic_namespace
    assert_equal 'rakelib', opts.rakelib
    assert ! RakeFileUtils.verbose_flag
    assert ! RakeFileUtils.nowrite_flag
  end

  def test_trace_option
    flags('--trace', '-t') do |opts|
      assert opts.trace
      assert RakeFileUtils.verbose_flag
      assert ! RakeFileUtils.nowrite_flag
    end
  end

  def test_dry_run
    flags('--dry-run', '-n') do |opts|
      assert opts.dryrun
      assert opts.trace
      assert RakeFileUtils.verbose_flag
      assert RakeFileUtils.nowrite_flag
    end
  end

  def test_help
    flags('--help', '-H') do |opts, output|
      assert_match(/\Arake/, @out)
      assert_match(/--help/, @out)
      assert_equal :exit, @exit
    end
  end

  def test_usage
    flags('--usage', '-h') do |opts, output|
      assert_match(/\Arake/, @out)
      assert_match(/\boptions\b/, @out)
      assert_match(/\btargets\b/, @out)
      assert_equal :exit, @exit
    end
  end

  def test_libdir
    flags(['--libdir', 'xx'], ['-I', 'xx'], ['-Ixx']) do |opts|
      $:.include?('xx')
    end
  ensure
    $:.delete('xx')
  end

  def test_nosearch
    flags('--nosearch', '-N') do |opts|
      assert opts.nosearch
    end
  end

  def test_show_prereqs
    flags('--prereqs', '-P') do |opts|
      assert opts.show_prereqs
    end
  end

  def test_quiet
    flags('--quiet', '-q') do |opts|
      assert ! RakeFileUtils.verbose_flag
      assert ! opts.silent
    end
  end

  def test_silent
    flags('--silent', '-s') do |opts|
      assert ! RakeFileUtils.verbose_flag
      assert opts.silent
    end
  end

  def test_rakefile
    flags(['--rakefile', 'RF'], ['--rakefile=RF'], ['-f', 'RF'], ['-fRF']) do |opts|
      assert_equal ['RF'], @app.instance_eval { @rakefiles }
    end
  end

  def test_rakelib
    flags(['--rakelibdir', 'A:B:C'], ['--rakelibdir=A:B:C'], ['-R', 'A:B:C'], ['-RA:B:C']) do |opts|
      assert_equal ['A', 'B', 'C'], opts.rakelib
    end
  end

  def test_require
    flags(['--require', 'test/reqfile'], '-rtest/reqfile2', '-rtest/reqfile3') do |opts|
    end
    assert TESTING_REQUIRE.include?(1)
    assert TESTING_REQUIRE.include?(2)
    assert TESTING_REQUIRE.include?(3)
    assert_equal 3, TESTING_REQUIRE.size
  end

  def test_missing_require
    ex = assert_raises(LoadError) do
      flags(['--require', 'test/missing']) do |opts|
      end
    end
    assert_match(/no such file/, ex.message)
    assert_match(/test\/missing/, ex.message)
  end

  def test_tasks
    flags('--tasks', '-T') do |opts|
      assert opts.show_tasks
      assert_equal(//.to_s, opts.show_task_pattern.to_s)
    end
    flags(['--tasks', 'xyz'], ['-Txyz']) do |opts|
      assert opts.show_tasks
      assert_equal(/xyz/, opts.show_task_pattern)
    end
  end

  def test_verbose
    flags('--verbose', '-V') do |opts|
      assert RakeFileUtils.verbose_flag
      assert ! opts.silent
    end
  end

  def test_version
    flags('--version', '-V') do |opts|
      assert_match(/\bversion\b/, @out)
      assert_match(/\b#{RAKEVERSION}\b/, @out)
      assert_equal :exit, @exit
    end
  end
  
  def test_classic_namespace
    flags(['--classic-namespace'], ['-C', '-T', '-P', '-n', '-s', '-t']) do |opts|
      assert opts.classic_namespace
      assert_equal opts.show_tasks, $show_tasks
      assert_equal opts.show_prereqs, $show_prereqs
      assert_equal opts.trace, $trace
      assert_equal opts.dryrun, $dryrun
      assert_equal opts.silent, $silent
    end
  end

  def test_bad_option
    capture_stderr do
      ex = assert_raise(GetoptLong::InvalidOption) { flags('--bad-option') }
      assert_match(/unrecognized option/, ex.message)
      assert_match(/--bad-option/, ex.message)
    end
  end

  def test_task_collection
    command_line("a", "b")
    assert_equal ["a", "b"], @tasks.sort
  end
  
  def test_default_task_collection
    command_line()
    assert_equal ["default"], @tasks
  end
  
  def test_environment_definition
    ENV['TESTKEY'] = nil
    command_line("a", "TESTKEY=12")
    assert_equal ["a"], @tasks.sort
    assert '12', ENV['TESTKEY']
  end
  
  private 

  def flags(*sets)
    sets.each do |set|
      @out = capture_stdout { 
        @exit = catch(:system_exit) { opts = command_line(*set) }
      }
      yield(@app.options)
    end
  end

  def command_line(*options)
    options.each do |opt| ARGV << opt end
    @app = Rake::Application.new
    def @app.exit(*args)
      throw :system_exit, :exit
    end
    @app.handle_options
    @tasks = @app.collect_tasks
    @app.options
  end
end

