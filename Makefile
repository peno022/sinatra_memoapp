null:
	@:

install:
	bundle install

up:
	open http://localhost:4567/ && bundle exec ruby memoapp.rb
