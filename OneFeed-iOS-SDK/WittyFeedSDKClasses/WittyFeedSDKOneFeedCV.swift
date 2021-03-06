//
//  WittyFeedSDKOneFeedCV.swift
//  wittyfeed_ios_api
//
//  Created by Vatsana Technologies on 03/04/18.
//  Copyright © 2018 wittyfeed. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire
import SafariServices

public class WittyFeedSDKOneFeedCV: UICollectionViewController, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, SFSafariViewControllerDelegate {
    
    //var onefeedsdk = OneFeedSdk()
    var screen_width = WittyFeedSDKSingleton.instance.screen_width
    var screen_height = WittyFeedSDKSingleton.instance.screen_height
    var wittyCardFactory: WittyFeedSDKCardFactory!
    var refreshControl: UIRefreshControl!
    var is_fetching_data = false
    var loadmore_offset: Int = 0
    var fetch_more_init_main_callback: (String) -> Void = {_ in }
    var activityIndicator = UIActivityIndicatorView()
    var str_to_search: String = ""
    var last_str_searched: String = ""
    var is_search_blocks = false
    var is_search_blocks_active = false
    var searchBar: UISearchBar!
    var searchActivityView: UIView!
    var resourceBundle: Bundle?
    var existing_status_bar_style: UIStatusBarStyle?
    var backButton: UIButton!
    var addButton: UIButton!
    var backButtonItem: UIBarButtonItem!
    var addButtonItem: UIBarButtonItem!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        let googleAnalytics = WittyFeedSDKGoogleAnalytics()
        googleAnalytics.sendAnalytics(typeArg: AnalyticsType.OneFeed, labelArg: "OneFeed viewed")
        
        self.navigationController?.isNavigationBarHidden = false
        let frameworkBundle = Bundle(for: WittyFeedSDKMain.self)
        let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("OneFeed-iOS-SDK.bundle")
        resourceBundle = Bundle(url: bundleURL!)

        searchActivityView = UIView( frame: CGRect(x: 0, y: 0, width: WittyFeedSDKSingleton.instance.screen_width, height: WittyFeedSDKSingleton.instance.screen_height) )
        searchActivityView.backgroundColor = .white
        activityIndicator.center = CGPoint(x: view.bounds.size.width/2, y: 100)
        activityIndicator.color = UIColor.darkGray
        searchActivityView.addSubview(activityIndicator)
        view?.addSubview(searchActivityView)
        
        searchActivityView.isHidden = true
        navigationController?.navigationBar.barTintColor = WittyFeedSDKSingleton.instance.NavBarColor
        
        self.navigationItem.setHidesBackButton(true, animated:true)
        //  self.navigationItem.leftBarButtonItems = leftNavBarButton
        registerNibs()
        addBackButton()
        wittyCardFactory = WittyFeedSDKCardFactory(text_size_ratio: 1.0)
        wittyCardFactory.safariDelegate = self as SFSafariViewControllerDelegate
        wittyCardFactory.vc_context = self
        
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action:  #selector(refresh), for: UIControlEvents.valueChanged)
        self.collectionView?.addSubview(self.refreshControl)
        
        collectionView?.keyboardDismissMode = .interactive
        collectionView?.keyboardDismissMode = .onDrag
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        existing_status_bar_style = UIApplication.shared.statusBarStyle
        UIApplication.shared.statusBarStyle = .default
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = existing_status_bar_style!
    }
    
    @objc func refresh(sender:AnyObject) {
        WittyFeedSDKSingleton.instance.wittyFeed_sdk_main.fetch_more_data(loadmore_offset: 0) { (status) in
                        if(status != "failed"){
                            self.refreshControl?.endRefreshing()
                            self.collectionView?.reloadData()
                        } else {
                            self.refreshControl?.endRefreshing()
                        }
        }
        
//        WittyFeedSDKSingleton.instance.wittyFeed_sdk_main.load_initial_data(isBackgroundCacheRefresh: false) { (status) in
//            if(status != "failed"){
//                self.refreshControl?.endRefreshing()
//                self.collectionView?.reloadData()
//            } else {
//                self.refreshControl?.endRefreshing()
//            }
//        }
    }
    
    func addBackButton() {
        backButton = UIButton(type: .custom)
        backButton.setImage(UIImage(named: "BackButton", in: resourceBundle, compatibleWith: nil), for: .normal)
        backButton.frame = CGRect(x: 0, y: 7, width: 30, height: 30)
        backButton.addTarget(self, action: #selector(WittyFeedSDKOneFeedCV.backAction), for: .touchUpInside)
        backButtonItem = UIBarButtonItem(customView: backButton)
        
       // addButton = UIButton(type: .custom)
       // addButton.setImage(UIImage(named: "plus", in: resourceBundle, compatibleWith: nil), for: .normal)
       // addButton.frame = CGRect(x: 0, y: 7, width: 30, height: 30)
       // addButton.addTarget(self, action: #selector(WittyFeedSDKOneFeedCV.addAction), for: .touchUpInside)
        //addButtonItem = UIBarButtonItem(customView: addButton)
        
        searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: WittyFeedSDKSingleton.instance.screen_width * 0.65, height: 20))
        navigationItem.titleView = searchBar
        
        searchBar.placeholder = "Search"
        searchBar.enablesReturnKeyAutomatically = false
        searchBar.delegate = self as UISearchBarDelegate
        
        self.navigationItem.setHidesBackButton(true, animated:true)
        self.navigationItem.setLeftBarButton(backButtonItem, animated: true)
       // self.navigationItem.setRightBarButton(addButtonItem, animated: true)
    }
    
    @IBAction func backAction(_ sender: UIButton) {
        if(is_search_blocks){
            self.searchBar!.text! = ""
            self.is_search_blocks = false
            self.collectionView?.reloadData()
            self.searchBar.resignFirstResponder()
            self.view.endEditing(true)
        } else {
            let _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func addAction(_ sender: UIButton) {
        let frameworkBundle = Bundle(for: WittyFeedSDKMain.self)
        let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("OneFeed-iOS-SDK.bundle")
        let resourceBundle = Bundle(url: bundleURL!)
       // let interestCollectionVC = WittyFeedSDKInterestsCV(nibName: "WittyFeedSDKInterestsCV", bundle: resourceBundle)
        //self.navigationController?.pushViewController(interestCollectionVC, animated: true)
    }
    
    public func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        last_str_searched = ""
        is_search_blocks_active = true
        self.collectionView?.reloadData()
        self.navigationItem.rightBarButtonItem = nil
        self.navigationItem.leftBarButtonItem = nil
        searchBar.showsCancelButton = true
       // searchActivityView.isHidden = false
        return true
    }
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if(is_search_blocks_active){
            self.searchBar!.text! = ""
            self.is_search_blocks_active = false
            self.collectionView?.reloadData()
            self.searchBar.resignFirstResponder()
            self.view.endEditing(true)
        } else {
            let _ = self.navigationController?.popViewController(animated: true)
        }
    
        self.searchBar.endEditing(true)
        searchBar.showsCancelButton = false
        searchActivityView.isHidden = true
        searchBar.text = ""
        if(is_search_blocks){
            self.searchBar!.text! = ""
            self.is_search_blocks = false
            self.collectionView?.reloadData()
            self.searchBar.resignFirstResponder()
            self.view.endEditing(true)
        } else {
           searchActivityView.isHidden = true
        }
     //   self.navigationItem.rightBarButtonItem = addButtonItem
        self.navigationItem.leftBarButtonItem = backButtonItem
        searchBar.resignFirstResponder()
    }
    
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if ConnectionCheck.isConnectedToNetwork() {
            self.searchBar.endEditing(true)
            str_to_search = searchBar.text!
            if str_to_search != "" {
                let googleAnalytics = WittyFeedSDKGoogleAnalytics()
                googleAnalytics.sendAnalytics(typeArg: .Search, labelArg: str_to_search)
                
            }
            if(str_to_search != last_str_searched && str_to_search != ""){
                searchActivityView.isHidden = false
                activityIndicator.startAnimating()
                WittyFeedSDKSingleton.instance.wittyFeed_sdk_main.search_content(search_input_str: str_to_search, loadmore_offset: 0, search_content_main_callback: { (status) in
                    if(status != "failed"){
                        self.last_str_searched = self.str_to_search;
                        self.is_search_blocks = true
                        self.searchActivityView.isHidden = true
                        self.collectionView?.reloadData()
                    } else {
                        
                        let alert = UIAlertController(title: self.str_to_search, message: "No results found", preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        self.searchActivityView.isHidden = true
                        self.activityIndicator.stopAnimating()
                        self.is_search_blocks = false
                        self.collectionView?.reloadData()
                    }
                })
            }
            
        }else{
            print("disConnected")
            let controller = UIAlertController(title: "No Internet Detected", message: "This app requires an Internet connection", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            controller.addAction(ok)
            controller.addAction(cancel)
            present(controller, animated: true, completion: nil)
        }
    }
    
    public func registerNibs() {
        collectionView?.backgroundColor = .white
        collectionView?.register(UINib(nibName: "SOLO_POSTER", bundle: resourceBundle), forCellWithReuseIdentifier: "SOLO_POSTER")
        collectionView?.register(UINib(nibName: "POSTER_CV", bundle: resourceBundle), forCellWithReuseIdentifier: "POSTER_CV")
        collectionView?.register(UINib(nibName: "SOLO_VIDEO", bundle: resourceBundle), forCellWithReuseIdentifier: "SOLO_VIDEO")
        collectionView?.register(UINib(nibName: "VIDEO_CV", bundle: resourceBundle), forCellWithReuseIdentifier: "VIDEO_CV")
        collectionView?.register(UINib(nibName: "STORY_LIST", bundle: resourceBundle), forCellWithReuseIdentifier: "STORY_LIST")
         collectionView?.register(UINib(nibName: "CollectionView1_4", bundle: resourceBundle), forCellWithReuseIdentifier: "CollectionView1_4")
        collectionView?.register(UINib(nibName: "WittyFeedSDKLoaderCell", bundle: resourceBundle), forCellWithReuseIdentifier: "WittyFeedSDKLoaderCell")
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if(is_search_blocks){
            return WittyFeedSDKSingleton.instance.search_blocks_arr.count
        } else if (is_search_blocks_active){
            return 1
        } else {
            return WittyFeedSDKSingleton.instance.block_arr.count + 1
        }
    }
    
    override public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var maincell : UICollectionViewCell = UICollectionViewCell()
        
        var local_collV_block_arr = [Block]()
        
        if(is_search_blocks){
            local_collV_block_arr = WittyFeedSDKSingleton.instance.search_blocks_arr
        }else if (is_search_blocks_active){
            local_collV_block_arr = WittyFeedSDKSingleton.instance.search_blocks_data_arr
        }  else {
            local_collV_block_arr = WittyFeedSDKSingleton.instance.block_arr
        }
        
        if local_collV_block_arr.count > indexPath.row{
            let card_type = local_collV_block_arr[indexPath.row].type
            let card_ARR = local_collV_block_arr[indexPath.row].card_arr!
            switch (card_type){
            case "poster_solo"?:
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SOLO_POSTER", for: indexPath) as? SOLO_POSTER {
                    
                    for subview in cell.solo_poster_view.subviews {
                        subview.removeFromSuperview()
                    }
                    let card = wittyCardFactory.create_single_card(card: card_ARR[0], card_type: card_type!)
                    let seperationView = UIView( frame: CGRect(x: 20, y: card.frame.height + 4, width: screen_width - 40, height: 2.0))
                    seperationView.backgroundColor = WittyFeedSDKSingleton.instance.NavBarColor
                    cell.solo_poster_view.addSubview(card)
                    cell.solo_poster_view.addSubview(seperationView)
                    return cell
                }
                break
            case "poster_rv"?:
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "POSTER_CV", for: indexPath) as? POSTER_CV {
                    for subview in cell.poster_view.subviews {
                        subview.removeFromSuperview()
                    }
                    let card = wittyCardFactory.create_cards_rv(cards: card_ARR, card_type: card_type!)
                    let seperationView = UIView( frame: CGRect(x: 20, y: card.frame.height + 4, width: screen_width - 40, height: 2.0))
                    seperationView.backgroundColor = WittyFeedSDKSingleton.instance.NavBarColor
                    cell.poster_view.addSubview(card)
                    cell.poster_view.addSubview(seperationView)
                    return cell
                }
                break
            case "video_solo"?:
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SOLO_VIDEO", for: indexPath) as? SOLO_VIDEO {
                    for subview in cell.solo_video_view.subviews {
                        subview.removeFromSuperview()
                    }
                    let card = wittyCardFactory.create_single_card(card: card_ARR[0], card_type: card_type!)
                    cell.solo_video_view.addSubview(card)
                    return cell
                }
                break
            case "video_rv"?:
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VIDEO_CV", for: indexPath) as? VIDEO_CV {
                    
                    for subview in cell.video_cv.subviews {
                        subview.removeFromSuperview()
                    }
                    let card = wittyCardFactory.create_cards_rv(cards: card_ARR, card_type: card_type!)
                    let seperationView = UIView( frame: CGRect(x: 20, y: card.frame.height + 4, width: screen_width - 40, height: 2.0))
                    seperationView.backgroundColor = WittyFeedSDKSingleton.instance.NavBarColor
                    cell.video_cv.addSubview(card)
                    cell.video_cv.addSubview(seperationView)
                    return cell
                }
                break
            case "story_list"?:
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "STORY_LIST", for: indexPath) as? STORY_LIST {
                    for subview in cell.story_list_view.subviews {
                        subview.removeFromSuperview()
                    }
                    let card = wittyCardFactory.create_cards_rv(cards: card_ARR, card_type: card_type!)
                    let seperationView = UIView( frame: CGRect(x: 20, y: card.frame.height + 4, width: screen_width - 40, height: 2.0))
                    seperationView.backgroundColor = WittyFeedSDKSingleton.instance.NavBarColor
                    cell.story_list_view.addSubview(card)
                    cell.story_list_view.addSubview(seperationView)
                    return cell
                }
                break
            case "collection_1_4"?:
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionView1_4", for: indexPath) as? CollectionView1_4 {
                    for subview in cell.searchBlockView.subviews {
                        subview.removeFromSuperview()
                    }
                    let card = wittyCardFactory.create_cards_rv(cards: card_ARR, card_type: card_type!)
                    let seperationView = UIView( frame: CGRect(x: 20, y: card.frame.height + 4, width: screen_width - 40, height: 2.0))
                    seperationView.backgroundColor = WittyFeedSDKSingleton.instance.NavBarColor
                    cell.searchBlockView.addSubview(card)
                    cell.searchBlockView.addSubview(seperationView)
                    return cell
                }
                break
            default:
                break
            }
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WittyFeedSDKLoaderCell", for: indexPath) as? WittyFeedSDKLoaderCell
            cell?.loaderActivity.startAnimating()
            maincell = cell!
        }
        
        return maincell
    }
    
    
    // MARK: - WaterfallLayoutDelegate
    public func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if(is_search_blocks){
            if WittyFeedSDKSingleton.instance.search_blocks_arr.count > indexPath.row {
                var size = wittyCardFactory.getCellSize(card_type: WittyFeedSDKSingleton.instance.search_blocks_arr[indexPath.row].type)
                
                if(WittyFeedSDKSingleton.instance.search_blocks_arr[indexPath.row].type == "story_list"){
                    size = wittyCardFactory.getCellSize(
                        card_type: WittyFeedSDKSingleton.instance.search_blocks_arr[indexPath.row].type,
                        story_list_count: CGFloat(WittyFeedSDKSingleton.instance.search_blocks_arr[indexPath.row].card_arr.count)
                    )
                }
                size.height = size.height + 8
                return size
            } else {
                if WittyFeedSDKSingleton.instance.search_blocks_arr.count < 1 {
                    return CGSize(width: screen_width, height: screen_height)
                } else {
                    return CGSize(width: screen_width, height: 50)
                }
            }
        } else if (is_search_blocks_active){
            return CGSize(width: screen_width, height: 200)
        }else {
            if WittyFeedSDKSingleton.instance.block_arr.count > indexPath.row {
                var size = wittyCardFactory.getCellSize(card_type: WittyFeedSDKSingleton.instance.block_arr[indexPath.row].type)
                if(WittyFeedSDKSingleton.instance.block_arr[indexPath.row].type == "story_list"){
                    return wittyCardFactory.getCellSize(
                        card_type: WittyFeedSDKSingleton.instance.block_arr[indexPath.row].type,
                        story_list_count: CGFloat(WittyFeedSDKSingleton.instance.block_arr[indexPath.row].card_arr.count)
                    )
                }
                size.height = size.height + 8
                return size
            } else {
                if WittyFeedSDKSingleton.instance.block_arr.count < 1 {
                    return CGSize(width: screen_width, height: screen_height)
                } else {
                    return CGSize(width: screen_width, height: 50)
                }
            }
        }
    }
    
    override public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if(is_search_blocks){
            return
        }
        let lastElement = WittyFeedSDKSingleton.instance.block_arr.count - 1
        
        if (is_fetching_data == false) {
            if(indexPath.row == lastElement){
                is_fetching_data = true
                loadmore_offset += 1
                if ConnectionCheck.isConnectedToNetwork() {
                    WittyFeedSDKSingleton.instance.wittyFeed_sdk_main.fetch_more_data(loadmore_offset: loadmore_offset, fetch_more_main_callback: { (status) in
                        self.fetch_more_init_main_callback(status)
                        if(status == "success"){
                            self.collectionView?.reloadData()
                            self.is_fetching_data = false
                        } else {
                            print("error")
                        }
                    })
                    
                }else{
                    self.is_fetching_data = false
                    print("disConnected")
                    let controller = UIAlertController(title: "No Internet Detected", message: "This app requires an Internet connection", preferredStyle: .alert)
                    let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
                    let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                    controller.addAction(ok)
                    controller.addAction(cancel)
                    present(controller, animated: true, completion: nil)
                }
            }
        }
    }
    
    func set_fetch_more__init_main_callback( init_callback:@escaping (String) -> Void  ){
        self.fetch_more_init_main_callback = init_callback
    }
    
}
