Publicwhip::Application.routes.draw do
  devise_for :users
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # Redirects
  get 'policies.php' => redirect('/policies')
  get 'policy.php' => redirect {|p,r| "/policies/#{r.query_parameters['id']}/edit"},
    constraints: lambda { |request| request.query_parameters["display"] == "editdefinition"}
  get 'policy.php' => redirect {|p,r| "/policies/#{r.query_parameters['id']}/detail"},
    constraints: lambda { |request| request.query_parameters["display"] == "motions"}
  get "policy.php" => redirect {|p,r| "/policies/#{r.query_parameters['id']}"}
  get '/account/addpolicy.php' => redirect("/policies/new")

  get '/account/changepass.php' => redirect('/users/edit')
  get '/account/changeemail.php' => redirect('/users/edit')

  get 'mps.php' => 'members#index_redirect',
    constraints: lambda {|r| r.query_parameters["house"] == "all" || r.query_parameters["house"].nil? || r.query_parameters["sort"] == "lastname" || r.query_parameters["parliament"]}
  get 'mps.php' => redirect {|p,r|
    if r.query_parameters["sort"]
      "/members/#{r.query_parameters['house']}?sort=#{r.query_parameters['sort']}"
    else
      "/members/#{r.query_parameters['house']}"
    end
  }
  get 'mp.php' => 'members#show_redirect',
    constraints: lambda {|r| r.query_parameters["mpid"] || r.query_parameters["id"]}
  get 'mp.php' => 'electorates#show_redirect',
    constraints: lambda {|r| r.query_parameters["mpn"].nil? && (r.query_parameters["display"] || r.query_parameters["dmp"] || r.query_parameters["house"].nil?)}
  get 'mp.php' => redirect{|p,r| "/members/#{r.query_parameters['house']}/#{r.query_parameters['mpc'].downcase}"},
    constraints: lambda {|r| r.query_parameters["mpn"].nil?}
  get 'mp.php' => 'members#show_redirect',
    constraints: lambda {|r| r.query_parameters["dmp"] && r.query_parameters["display"] == "allvotes"}
  get 'mp.php' => 'members#show_redirect',
    constraints: lambda {|r| r.query_parameters["display"] == "summary" || r.query_parameters["display"] == "alldreams" || r.query_parameters["display"] == "allvotes" || r.query_parameters["showall"] == "yes"}
  get 'mp.php' => 'members#show_redirect',
    constraints: lambda {|r| r.query_parameters["mpc"] == "Senate" || r.query_parameters["mpc"].nil? || r.query_parameters["house"].nil?}
  get 'mp.php' => redirect{|p,r|
    "/members/#{r.query_parameters['house']}/#{r.query_parameters['mpc'].downcase}/#{r.query_parameters['mpn'].downcase}/friends"
  }, constraints: lambda {|r| r.query_parameters["display"] == "allfriends" && r.query_parameters[:dmp].nil?}
  get 'mp.php' => redirect{|p,r|
    "/members/#{r.query_parameters['house']}/#{r.query_parameters['mpc'].downcase}/#{r.query_parameters['mpn'].downcase}/divisions"
  }, constraints: lambda {|r| r.query_parameters["display"] == "everyvote" && r.query_parameters[:dmp].nil?}
  get 'mp.php' => redirect{|p,r|
    "/members/#{r.query_parameters['house']}/#{r.query_parameters['mpc'].downcase}/#{r.query_parameters['mpn'].downcase}/policies/#{r.query_parameters['dmp']}/full"
  }, constraints: lambda {|r| r.query_parameters["display"] == "motions" && r.query_parameters[:dmp]}
  get 'mp.php' => redirect{|p,r|
    result = "/members/#{r.query_parameters['house']}/#{r.query_parameters['mpc'].downcase}/#{r.query_parameters['mpn'].downcase}"
    result += "/policies/#{r.query_parameters['dmp']}" if r.query_parameters['dmp']
    queries = []
    queries << "display=#{r.query_parameters['display']}" if r.query_parameters["display"]
    result += "?" + queries.join("&") unless queries.empty?
    result
  }

  # Main routes
  root 'home#index'

  get 'index.php' => 'home#index'
  get 'faq.php' => 'home#faq', as: :help
  get 'search.php' => 'home#search', as: :search

  get '/members/:house' => 'members#index', as: :members
  get '/members/:house/:mpc' => 'electorates#show', as: :electorate
  get '/members/:house/:mpc/:mpn' => 'members#show', as: :member
  get '/members/:house/:mpc/:mpn/policies/:dmp' => 'members#policy', as: :member_policy
  get '/members/:house/:mpc/:mpn/policies/:dmp/full' => 'members#full', as: :full_member_policy
  get '/members/:house/:mpc/:mpn/friends' => 'members#friends', as: :friends_member
  get '/members/:house/:mpc/:mpn/divisions' => 'members#votes', as: :votes_member

  get 'divisions.php' => 'divisions#index_redirect',
    constraints: lambda {|r| r.query_parameters["rdisplay2"] == "rebels"}
  get 'divisions.php' => 'divisions#index', as: :divisions
  get 'division.php' => 'divisions#show_redirect',
    constraints: lambda {|r| r.query_parameters["sort"]}
  get 'division.php' => 'divisions#show_redirect',
    constraints: lambda {|r| r.query_parameters["display"] == "allvotes" || r.query_parameters["display"] == "allpossible"}
  get 'division.php' => 'divisions#show_redirect',
    constraints: lambda {|r| r.query_parameters["house"].nil? }
  get 'division.php' => redirect{|p,r| "/divisions/#{r.query_parameters['house']}/#{r.query_parameters['date']}/#{r.query_parameters['number']}/policies/#{r.query_parameters['dmp']}"},
    constraints: lambda {|r| r.query_parameters["display"] == "policies" && r.query_parameters["dmp"]}
  get 'division.php' => redirect{|p,r| "/divisions/#{r.query_parameters['house']}/#{r.query_parameters['date']}/#{r.query_parameters['number']}/policies"},
    constraints: lambda {|r| r.query_parameters["display"] == "policies"}
  get '/divisions/:house/:date/:number/policies' => 'divisions#show_policies'
  get '/divisions/:house/:date/:number/policies/:dmp' => 'divisions#show_policies'
  get 'division.php' => 'divisions#show_redirect',
    constraints: lambda {|r| r.query_parameters["mpc"] == "Senate"}
  get 'division.php' => redirect{|p,r| "/divisions/#{r.query_parameters['house']}/#{r.query_parameters['date']}/#{r.query_parameters['number']}"},
    constraints: lambda {|r| r.query_parameters["display"].nil? && r.query_parameters["mpn"].nil?}
  get 'division.php' => redirect{|p,r| "/members/#{r.query_parameters['house']}/#{r.query_parameters['mpc'].downcase}/#{r.query_parameters['mpn'].downcase}/divisions/#{r.query_parameters['date']}/#{r.query_parameters['number']}"},
    constraints: lambda {|r| r.query_parameters["mpn"] && r.query_parameters["mpc"]}
  get 'division.php' => 'divisions#show', as: :division
  get '/divisions/:house/:date/:number' => 'divisions#show'
  get '/members/:house/:mpc/:mpn/divisions/:date/:number' => 'divisions#show'
  post 'division.php' => 'divisions#add_policy_vote'
  get 'edits.php' => 'divisions#show_edits', as: :show_edits_division
  get 'account/wiki.php' => redirect{|p,r| "/divisions/#{r.query_parameters['house']}/#{r.query_parameters['date']}/#{r.query_parameters['number']}/edit"}, as: :edit_division
  get '/divisions/:house/:date/:number/edit' => 'divisions#edit'
  post 'account/wiki.php' => 'divisions#update'

  post 'redir.php', to: redirect { |p, r| (r.params[:r] || r.params[:r2] || r.params[:r3]) }, as: :redirect

  resources :policies, except: :destroy do
    get 'detail', on: :member
  end

  match 'account/settings.php' => 'account#settings', via: [:get, :post], as: :account_settings

  devise_scope :user do
    get '/account/logout.php' => 'devise/sessions#destroy', as: :logout
    get '/account/register.php' => 'devise/registrations#new', as: :sign_up
  end

  get 'feeds/mp-info' => 'feeds#mp_info', as: :mp_info_feed
  get 'feeds/mpdream-info' => 'feeds#mpdream_info', as: :mpdream_info_feed

  get 'project/code.php', to: redirect('https://github.com/openaustralia/publicwhip/')
  get 'project/data.php' => 'static#data', as: :data_help
  get 'project/research.php' => 'static#research', as: :research_help

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
