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

  def initialize(options = {})
    @id = options["id"]
    @fname = options["fname"]
    @lname = options["lname"]
  end

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

end

class Question

  attr_reader :id, :title, :body, :user_id

  def initialize(options = {})
    @id = options["id"]
    @title = options["title"]
    @body = options["body"]
    @user_id = options["user_id"]
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

end

class QuestionFollower

  attr_reader :id, :question_id, :user_id

  def initialize(options = {})
    @id = options["id"]
    @question_id = options["question_id"]
    @user_id = options["user_id"]
  end

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

end

class Reply

  attr_reader :id, :question_id, :user_id, :parent_id, :body

  def initialize(options = {})
    @id = options["id"]
    @question_id = options["question_id"]
    @user_id = options["user_id"]
    @parent_id = options["parent_id"]
    @body = options["body"]
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

end

class QuestionLike

  attr_reader :id, :question_id, :user_id, :liked

  def initialize(options = {})
    @id = options["id"]
    @question_id = options["question_id"]
    @user_id = options["user_id"]
    @liked = options["liked"]
  end

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

end