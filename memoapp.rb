# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/flash'
require 'json'
require 'pg'

enable :sessions

ERROR_MESSAGE_MEMO_NOT_EXIST = '対象のメモデータがありません。'
ERROR_MESSAGE_EMPTY_MEMO = 'タイトル、内容にはテキストを入力してください。'

DB = {
  db_name: 'sinatra_memoapp',
  host: 'localhost',
  user: 'postgres',
  port: 5432
}.freeze

class Memo
  attr_accessor :title, :content
  attr_reader :id, :created_at, :updated_at

  def initialize(id, title, content, created_at, updated_at)
    @id = id
    @title = title
    @content = content
    @created_at = created_at
    @updated_at = updated_at
  end

  def self.all
    db_exec('SELECT * FROM memos').to_a.map do |memo_hash_object|
      Memo.new(memo_hash_object['id'], memo_hash_object['title'], memo_hash_object['content'], memo_hash_object['created_at'], memo_hash_object['updated_at'])
    end
  end

  def self.find_by_id(id)
    memo_hash_objects = db_exec("SELECT * FROM memos WHERE id = '#{id}';").to_a
    return if memo_hash_objects.empty?

    memo_hash_objects.map do |memo_hash_object|
      Memo.new(
        memo_hash_object['id'], memo_hash_object['title'], memo_hash_object['content'], memo_hash_object['created_at'], memo_hash_object['updated_at']
      )
    end.first
  end

  def create
    db_exec("INSERT INTO memos(title, content) VALUES ('#{title}', '#{content}');")
  end

  def delete
    db_exec("DELETE FROM memos WHERE id = '#{id}';")
  end

  def update
    db_exec("UPDATE memos SET title='#{title}', content='#{content}'
                , updated_at=CURRENT_TIMESTAMP where id = '#{id}';")
  end
end

get '/' do
  redirect '/memos'
  erb :index
end

get '/memos' do
  @memos = Memo.all
  erb :index
end

get '/memos/new' do
  erb :new
end

get '/memos/edit/:id' do
  target_memo = Memo.find_by_id(params['id'])
  unless target_memo
    show_error_message(ERROR_MESSAGE_MEMO_NOT_EXIST)
    redirect '/memos'
    return
  end
  @memo = target_memo
  erb :edit
end

get '/memos/:id' do
  @memo = Memo.find_by_id(params['id'])
  erb :detail
end

post '/memos' do
  if params['title'].strip.empty? || params['content'].strip.empty?
    show_error_message(ERROR_MESSAGE_EMPTY_MEMO)
    redirect '/memos/new'
    return
  end

  memo = Memo.new(nil, params['title'], params['content'], nil, nil)
  memo.create
  redirect '/memos'
  erb :index
end

patch '/memos/:id' do
  target_memo = Memo.find_by_id(params['id'])
  unless target_memo
    show_error_message(ERROR_MESSAGE_MEMO_NOT_EXIST)
    redirect '/memos'
    return
  end

  if params['title'].strip.empty? || params['content'].strip.empty?
    show_error_message(ERROR_MESSAGE_EMPTY_MEMO)
    redirect "/memos/#{params['id']}"
    return
  end

  target_memo.title = params['title']
  target_memo.content = params['content']
  target_memo.update
  redirect '/memos'
  erb :index
end

delete '/memos/:id' do
  target_memo = Memo.find_by_id(params['id'])
  unless target_memo
    show_error_message(ERROR_MESSAGE_MEMO_NOT_EXIST)
    redirect '/memos'
    return
  end

  target_memo.delete
  redirect '/memos'
  erb :index
end

def show_error_message(message)
  flash[:error] = message
end

def db_exec(sql)
  PG.connect(host: DB[:host], port: DB[:port], dbname: DB[:db_name], user: DB[:user]).exec(sql)
end
