require 'singleton'
require 'sqlite3'

class QuestionsDatabase < SQLite3::Database

  include Singleton

  def initialize
    super("questions.db")

    self.results_as_hash = true
    self.type_translation = true
  end
end

class User
  # raise "User already exists!" unless self.id.nil?
  attr_reader :id, :fname, :lname

  def self.find_by_id(id)
   options = QuestionsDatabase.instance.execute(<<-SQL, id)
     SELECT
       *
     FROM
       users
     WHERE
       id = ?
   SQL

   User.new(options[0])
  end

  def self.find_by_name(fname, lname)
    options = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
        fname = ? AND lname = ?
    SQL

    User.new(options[0])

  end

  def initialize(options = {})
    @id = options["id"]
    @fname = options["fname"]
    @lname = options["lname"]
  end

  def authored_questions
    Question.find_by_user_id(@id)
  end

  def authored_replies
    Reply.find_by_user_id(@id)
  end

end

class Question

  attr_reader :id, :title, :body, :user_id

  def self.find_by_author_id
    # will want to use this in authored questions

  end

  def self.find_by_user_id(user_id)
    options = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        questions
      WHERE
        user_id = ?
    SQL

    options.map { |option| Question.new(option) }
  end

  def self.find_by_id(id)
   options = QuestionsDatabase.instance.execute(<<-SQL, id)
     SELECT
       *
     FROM
       questions
     WHERE
       id = ?
   SQL

   Question.new(options[0])
  end

  def initialize(options = {})
    @id = options["id"]
    @title = options["title"]
    @body = options["body"]
    @user_id = options["user_id"]
  end

end

class QuestionFollower

  attr_reader :id, :question_id, :user_id

  def self.find_by_id(id)
   options = QuestionsDatabase.instance.execute(<<-SQL, id)
     SELECT
       *
     FROM
       question_followers
     WHERE
       id = ?
   SQL

   QuestionFollower.new(options[0])
  end

  def initialize(options = {})
    @id = options["id"]
    @question_id = options["question_id"]
    @user_id = options["user_id"]
  end

end

class Reply

  attr_reader :id, :question_id, :user_id, :parent_id, :body

  def self.find_by_user_id(user_id)
    options = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        replies
      WHERE
        user_id = ?
    SQL

    options.map { |option| Reply.new(option) }
  end

  def self.find_by_id(id)
   options = QuestionsDatabase.instance.execute(<<-SQL, id)
     SELECT
       *
     FROM
       replies
     WHERE
       id = ?
   SQL

   Reply.new(options[0])
  end

  def initialize(options = {})
    @id = options["id"]
    @question_id = options["question_id"]
    @user_id = options["user_id"]
    @parent_id = options["parent_id"]
    @body = options["body"]
  end

end

class QuestionLike

  attr_reader :id, :question_id, :user_id, :liked

  def self.find_by_id(id)
   options = QuestionsDatabase.instance.execute(<<-SQL, id)
     SELECT
       *
     FROM
       question_likes
     WHERE
       id = ?
   SQL

   QuestionLike.new(options[0])
  end

  def initialize(options = {})
    @id = options["id"]
    @question_id = options["question_id"]
    @user_id = options["user_id"]
    @liked = options["liked"]
  end

end