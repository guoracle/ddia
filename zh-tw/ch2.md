# 第二章 定義非功能性要求

> 網際網路做得太棒了，以至於大多數人將它看作像太平洋這樣的自然資源，而不是什麼人工產物。上一次出現這種大規模且無差錯的技術，你還記得是什麼時候嗎？
>
> —— [艾倫・凱](http://www.drdobbs.com/architecture-and-design/interview-with-alan-kay/240003442) 在接受 Dobb 博士雜誌採訪時說（2012 年）

--------

如果您正在構建應用程式，您將由一系列需求所驅動。在您需求列表的最頂端，很可能是應用程式必須提供的功能：需要哪些螢幕和按鈕，以及每個操作應如何執行以滿足軟體的目的。這些是您的*功能性需求*。

此外，您可能還有一些*非功能性需求*：例如，應用應該快速、可靠、安全、合法合規，並且易於維護。這些需求可能沒有明確書寫下來，因為它們似乎有些顯而易見，但它們和應用的功能一樣重要：一個異常緩慢或不可靠的應用可能根本無法存在。

並非所有非功能性需求都屬於本書的討論範圍，但有幾個是如此。在本章中，我們將介紹幾個技術概念，這將幫助您明確自己系統的非功能性需求：

- 如何定義和衡量系統的*效能*（見[“描述效能”](#描述效能)）；
- 服務*可靠*的含義——即使在出現問題時，也能繼續正確工作（見[“可靠性與容錯”](#可靠性與容錯)）；
- 允許系統透過有效地增加計算能力來*可擴充套件*，隨著系統負載的增長（見[“可伸縮性”](#可伸縮性)）；以及
- 長期易於維護系統（見[“可維護性”](#可維護性)）。

本章引入的術語在後續章節中也將非常有用，當我們詳細探討資料密集型系統的實現方式時。然而，抽象的定義可能相當枯燥；為了使這些概念更具體，我們將從社交網路服務的案例研究開始本章，這將提供效能和可擴充套件性的實際示例。

If you are building an application, you will be driven by a list of requirements. At the top of your list is most likely the functionality that the application must offer: what screens and what buttons you need, and what each operation is supposed to do in order to fulfill the purpose of your software. These are your *functional requirements*.

In addition, you probably also have some *nonfunctional requirements*: for example, the app should be fast, reliable, secure, legally compliant, and easy to maintain. These requirements might not be explicitly written down, because they may seem somewhat obvious, but they are just as important as the app’s functionality: an app that is unbearably slow or unreliable might as well not exist.

Not all nonfunctional requirements fall within the scope of this book, but several do. In this chapter we will introduce several technical concepts that will help you articulate the nonfunctional requirements for your own systems:

- How to define and measure the *performance* of a system (see [“Describing Performance”](ch02.html#sec_introduction_percentiles));
- What it means for a service to be *reliable*—namely, continuing to work correctly, even when things go wrong (see [“Reliability and Fault Tolerance”](ch02.html#sec_introduction_reliability));
- Allowing a system to be *scalable* by having efficient ways of adding computing capacity as the load on the system grows (see [“Scalability”](ch02.html#sec_introduction_scalability)); and
- Making it easier to maintain a system in the long term (see [“Maintainability”](ch02.html#sec_introduction_maintainability)).

The terminology introduced in this chapter will also be useful in the following chapters, when we go into the details of how data-intensive systems are implemented. However, abstract definitions can be quite dry; to make the ideas more concrete, we will start this chapter with a case study of how a social networking service might work, which will provide practical examples of performance and scalability.


--------

## 案例學習：社交網路主頁時間線

假設你被分配了一個任務，要實現一個類似X（前身為Twitter）的社交網路，在這個網路中，使用者可以釋出訊息並關注其他使用者。這將是對這種服務實際工作方式的極大簡化 [[1](ch02.html#Cvet2016), [2](ch02.html#Krikorian2012_ch2), [3](ch02.html#Twitter2023)]，但它將有助於說明大規模系統中出現的一些問題。

假設使用者每天釋出 5 億條訊息，平均每秒 5700 條訊息。偶爾，這個速率可能會激增至每秒 150,000 條訊息 [[4](ch02.html#Krikorian2013)]。我們還假設平均每個使用者關注 200 人，擁有 200 名粉絲（儘管這個範圍非常廣泛：大多數人只有少數幾個粉絲，而像巴拉克·奧巴馬這樣的名人粉絲超過 1 億）。


Imagine you are given the task of implementing a social network in the style of X (formerly Twitter), in which users can post messages and follow other users. This will be a huge simplification of how such a service actually works [[1](ch02.html#Cvet2016), [2](ch02.html#Krikorian2012_ch2), [3](ch02.html#Twitter2023)], but it will help illustrate some of the issues that arise in large-scale systems.

Let’s assume that users make 500 million posts per day, or 5,700 posts per second on average. Occasionally, the rate can spike as high as 150,000 posts/second [[4](ch02.html#Krikorian2013)]. Let’s also assume that the average user follows 200 people and has 200 followers (although there is a very wide range: most people have only a handful of followers, and a few celebrities such as Barack Obama have over 100 million followers).

### 使用者、帖子和關注關係的表示


設想我們將所有資料儲存在關係資料庫中，如 [圖 2-1](ch02.html#fig_twitter_relational) 所示。我們有一個使用者表、一個帖子表和一個關注關係表。

Imagine we keep all of the data in a relational database as shown in [Figure 2-1](ch02.html#fig_twitter_relational). We have one table for users, one table for posts, and one table for follow relationships.

![ddia 0102](../img/ddia_0102.png)

> 圖 2-1. 社交網路的簡單關係模式，其中使用者可以相互關注。

假設我們的社交網路需要支援的主要讀操作是*首頁時間線*，它顯示你所關注的人最近的帖子（為簡單起見，我們將忽略廣告、來自你未關注的人的建議帖子以及其他擴充套件）。我們可以編寫以下 SQL 查詢來獲取特定使用者的首頁時間線：

> Figure 2-1. Simple relational schema for a social network in which users can follow each other.

Let’s say the main read operation that our social network must support is the *home timeline*, which displays recent posts by people you are following (for simplicity we will ignore ads, suggested posts from people you are not following, and other extensions). We could write the following SQL query to get the home timeline for a particular user:

```sql
SELECT posts.*, users.* FROM posts
  JOIN follows ON posts.sender_id = follows.followee_id
  JOIN users   ON posts.sender_id = users.id
  WHERE follows.follower_id = current_user
  ORDER BY posts.timestamp DESC
  LIMIT 1000
```

為了執行這個查詢，資料庫將使用 `follows` 表來查詢 `current_user` 正在關注的所有人，查詢這些使用者的最近帖子，並按時間戳排序以獲得被關注使用者的最新 1000 條帖子。

帖子應當是及時的，因此假設某人發帖後，我們希望他們的關注者在 5 秒內能看到。一種實現這一目標的方法是，當用戶線上時，其客戶端每 5 秒重複上述查詢一次（這被稱為*輪詢*）。如果我們假設有 1000 萬用戶同時線上並登入，這意味著每秒需要執行 200 萬次查詢。即使你增加輪詢間隔，這也是一個龐大的數字。

此外，上述查詢相當昂貴：如果你關注了 200 人，它需要獲取這 200 人的最近帖子列表，併合並這些列表。每秒 200 萬次時間線查詢意味著資料庫需要每秒查詢某些傳送者的最近帖子 4 億次——這是一個巨大的數字。而這只是平均情況。有些使用者關注了成千上萬的賬戶；對他們而言，這個查詢非常昂貴，難以快速執行。

To execute this query, the database will use the `follows` table to find everybody who `current_user` is following, look up recent posts by those users, and sort them by timestamp to get the most recent 1,000 posts by any of the followed users.

Posts are supposed to be timely, so let’s assume that after somebody makes a post, we want their followers to be able to see it within 5 seconds. One way of doing that would be for the user’s client to repeat the query above every 5 seconds while the user is online (this is known as *polling*). If we assume that 10 million users are online and logged in at the same time, that would mean running the query 2 million times per second. Even if you increase the polling interval, this is a lot.

Moreover, the query above is quite expensive: if you are following 200 people, it needs to fetch a list of recent posts by each of those 200 people, and merge those lists. 2 million timeline queries per second then means that the database needs to look up the recent posts from some sender 400 million times per second—a huge number. And that is the average case. Some users follow tens of thousands of accounts; for them, this query is very expensive to execute, and difficult to make fast.

### 物化與更新時間線

我們怎樣才能做得更好？首先，與其使用輪詢，不如讓伺服器主動將新帖推送給當前線上的任何關注者。其次，我們應該預計算上述查詢的結果，以便使用者請求他們的首頁時間線時可以從快取中獲取。

想象一下，對於每個使用者，我們儲存一個包含他們首頁時間線的資料結構，即他們所關注的人的最近帖子。每當使用者發表帖子時，我們查詢他們所有的關注者，並將該帖子插入到每個關注者的首頁時間線中——就像將資訊送達郵箱一樣。現在，當用戶登入時，我們可以簡單地提供我們預計算的這個首頁時間線。此外，為了接收其時間線上任何新帖子的通知，使用者的客戶端只需訂閱被新增到他們首頁時間線的帖子流。

這種方法的缺點是，每當使用者發帖時，我們都需要做更多的工作，因為首頁時間線是派生資料，需要更新。這一過程在 [圖 2-2](ch02.html#fig_twitter_timelines) 中有所示。當一個初始請求導致執行多個下游請求時，我們使用*擴散*一詞來描述請求數量的增加因素。

How can we do better? Firstly, instead of polling, it would be better if the server actively pushed new posts to any followers who are currently online. Secondly, we should precompute the results of the query above so that a user’s request for their home timeline can be served from a cache.

Imagine that for each user we store a data structure containing their home timeline, i.e., the recent posts by people they are following. Every time a user makes a post, we look up all of their followers, and insert that post into the home timeline of each follower—like delivering a message to a mailbox. Now when a user logs in, we can simply give them this home timeline that we precomputed. Moreover, to receive a notification about any new posts on their timeline, the user’s client simply needs to subscribe to the stream of posts being added to their home timeline.

The downside of this approach is that we now need to do more work every time a user makes a post, because the home timelines are derived data that needs to be updated. The process is illustrated in [Figure 2-2](ch02.html#fig_twitter_timelines). When one initial request results in several downstream requests being carried out, we use the term *fan-out* to describe the factor by which the number of requests increases.

![ddia 0103](../img/ddia_0103.png)

> 圖 2-2. 扇出: 將新推文傳達給發帖使用者的每個關注者

以每秒 5700 帖的速率，如果平均每個帖子達到 200 個關注者（即擴散因子為 200），我們將需要每秒執行超過 100 萬次首頁時間線寫入。這個數字雖然大，但與我們原本需要執行的每秒 4 億次按傳送者查詢帖子相比，仍然是一個顯著的節省。

如果由於某些特殊事件導致帖子釋出率激增，我們不必立即執行時間線傳遞——我們可以將它們排隊，並接受帖子在關注者時間線上顯示出來可能會暫時延遲一些。即使在此類負載激增期間，時間線的載入仍然很快，因為我們只需從快取中提供它們。

這種預計算和更新查詢結果的過程被稱為*實體化*，而時間線快取則是一個*實體化檢視*的例子（這是我們將進一步討論的一個概念）。實體化的缺點是，每當一位名人發帖時，我們現在必須做大量的工作，將那篇帖子插入他們數百萬關注者的首頁時間線中。

解決這個問題的一種方法是將名人的帖子與其他人的帖子分開處理：我們可以透過將名人的帖子單獨儲存並在讀取時與實體化時間線合併，從而避免將它們新增到數百萬時間線上的努力。儘管有此類最佳化，處理社交網路上的名人可能需要大量的基礎設施 [[5](ch02.html#Axon2010_ch2)]。

At a rate of 5,700 posts posted per second, if the average post reaches 200 followers (i.e., a fan-out factor of 200), we will need to do just over 1 million home timeline writes per second. This is a lot, but it’s still a significant saving compared to the 400 million per-sender post lookups per second that we would otherwise have to do.

If the rate of posts spikes due to some special event, we don’t have to do the timeline deliveries immediately—we can enqueue them and accept that it will temporarily take a bit longer for posts to show up in followers’ timelines. Even during such load spikes, timelines remain fast to load, since we simply serve them from a cache.

This process of precomputing and updating the results of a query is called *materialization*, and the timeline cache is an example of a *materialized view* (a concept we will discuss further in [Link to Come]). The downside of materialization is that every time a celebrity makes a post, we now have to do a large amount of work to insert that post into the home timelines of each of their millions of followers.

One way of solving this problem is to handle celebrity posts separately from everyone else’s posts: we can save ourselves the effort of adding them to millions of timelines by storing the celebrity posts separately and merging them with the materialized timeline when it is read. Despite such optimizations, handling celebrities on a social network can require a lot of infrastructure [[5](ch02.html#Axon2010_ch2)].









--------

## 描述效能

在軟體效能的討論中，通常考慮兩種主要的度量指標：

- **響應時間**（Response Time）

  從使用者發出請求的那一刻到他們接收到請求的答案所經歷的時間。測量單位是秒。

- **吞吐量**（Throughput）

  系統每秒處理的請求數量或每秒處理的資料量。對於給定的硬體資源配置，存在一個*最大吞吐量*。測量單位是“每秒某事物數”。

在社交網路案例研究中，“每秒帖子數”和“每秒時間線寫入數”是吞吐量指標，而“載入首頁時間線所需的時間”或“帖子傳遞給關注者的時間”是響應時間指標。

吞吐量與響應時間之間通常存在聯絡；線上服務中這種關係的一個示例在 [圖 2-3](ch02.html#fig_throughput) 中進行了描述。當請求吞吐量低時，服務具有低響應時間，但隨著負載增加，響應時間會增長。這是因為*排隊*：當請求到達一個負載較高的系統時，很可能 CPU 正在處理先前的請求，因此新來的請求需要等待直到先前的請求完成。當吞吐量接近硬體能夠處理的最大值時，排隊延遲會急劇增加。


Most discussions of software performance consider two main types of metric:

- Response Time

  The elapsed time from the moment when a user makes a request until they receive the requested answer. The unit of measurement is seconds.

- Throughput

  The number of requests per second, or the data volume per second, that the system is processing. For a given a particular allocation of hardware resources, there is a *maximum throughput* that can be handled. The unit of measurement is “somethings per second”.

In the social network case study, “posts per second” and “timeline writes per second” are throughput metrics, whereas the “time it takes to load the home timeline” or the “time until a post is delivered to followers” are response time metrics.

There is often a connection between throughput and response time; an example of such a relationship for an online service is sketched in [Figure 2-3](ch02.html#fig_throughput). The service has a low response time when request throughput is low, but response time increases as load increases. This is because of *queueing*: when a request arrives on a highly loaded system, it’s likely that the CPU is already in the process of handling an earlier request, and therefore the incoming request needs to wait until the earlier request has been completed. As throughput approaches the maximum that the hardware can handle, queueing delays increase sharply.

![ddia 0104b](../img/ddia_0104b.png)

> 圖2-3. 當服務吞吐量接近容量時，響應時間會由於排隊而急劇增加


#### 當過載系統無法恢復時

如果系統接近過載，吞吐量接近極限，有時會進入一個惡性迴圈，使得系統變得效率更低，從而更加過載。例如，如果有大量請求在排隊等待處理，響應時間可能會增加到客戶端超時並重新發送請求的程度。這會導致請求率進一步增加，使問題更加嚴重——這就是所謂的*重試風暴*。即使負載再次減少，這樣的系統也可能仍處於過載狀態，直到重新啟動或以其他方式重置。這種現象稱為*亞穩定故障*，可能會導致生產系統中嚴重的中斷[[6](ch02.html#Bronson2021), [7](ch02.html#Brooker2021)]。

為了避免重試過度載入服務，你可以增加並隨機化客戶端連續重試之間的時間（*指數退避*[[8](ch02.html#Brooker2015), [9](ch02.html#Brooker2022backoff)]），並暫時停止向最近返回錯誤或超時的服務傳送請求（使用*斷路器*[[10](ch02.html#Nygard2018)]或*令牌桶*演算法[[11](ch02.html#Brooker2022retries)]）。伺服器也可以檢測到它即將過載，並開始主動拒絕請求（*減載*[[12](ch02.html#YanacekLoadShedding)]），併發送回響應要求客戶端減慢速度（*反壓力*[[1](ch02.html#Cvet2016), [13](ch02.html#Sackman2016_ch2)]）。佇列和負載平衡演算法的選擇也可以有所不同[[14](ch02.html#Kopytkov2018)]。

在效能指標方面，響應時間通常是使用者最關心的，而吞吐量決定了所需的計算資源（例如，你需要多少伺服器），從而決定了服務特定工作負載的成本。如果吞吐量可能超過當前硬體能夠處理的範圍，就需要擴充套件容量；如果一個系統能夠透過增加計算資源顯著提高其最大吞吐量，則稱該系統具有*可擴充套件性*。

在本節中，我們將主要關注響應時間，並將在[“可擴充套件性”](ch02.html#sec_introduction_scalability)一節中迴歸討論吞吐量和可擴充套件性。


If a system is close to overload, with throughput pushed close to the limit, it can sometimes enter a vicious cycle where it becomes less efficient and hence even more overloaded. For example, if there is a long queue of requests waiting to be handled, response times may increase so much that clients time out and resend their request. This causes the rate of requests to increase even further, making the problem worse—a *retry storm*. Even when the load is reduced again, such a system may remain in an overloaded state until it is rebooted or otherwise reset. This phenomenon is called a *metastable failure*, and it can cause serious outages in production systems [[6](ch02.html#Bronson2021), [7](ch02.html#Brooker2021)].

To avoid retries overloading a service, you can increase and randomize the time between successive retries on the client side (*exponential backoff* [[8](ch02.html#Brooker2015), [9](ch02.html#Brooker2022backoff)]), and temporarily stop sending requests to a service that has returned errors or timed out recently (using a *circuit breaker* [[10](ch02.html#Nygard2018)] or *token bucket* algorithm [[11](ch02.html#Brooker2022retries)]). The server can also detect when it is approaching overload and start proactively rejecting requests (*load shedding* [[12](ch02.html#YanacekLoadShedding)]), and send back responses asking clients to slow down (*backpressure* [[1](ch02.html#Cvet2016), [13](ch02.html#Sackman2016_ch2)]). The choice of queueing and load-balancing algorithms can also make a difference [[14](ch02.html#Kopytkov2018)].

In terms of performance metrics, the response time is usually what users care about the most, whereas the throughput determines the required computing resources (e.g., how many servers you need), and hence the cost of serving a particular workload. If throughput is likely to increase beyond what the current hardware can handle, the capacity needs to be expanded; a system is said to be *scalable* if its maximum throughput can be significantly increased by adding computing resources.

In this section we will focus primarily on response times, and we will return to throughput and scalability in [“Scalability”](ch02.html#sec_introduction_scalability).

### 延遲與響應時間

“Latency”和“response time”有時被交替使用，但在本書中，我們將以特定的方式使用這些術語（如[圖2-4](ch02.html#fig_response_time)所示）：

- *響應時間*是客戶端所看到的；它包括系統中任何地方產生的所有延遲。
- *服務時間*是服務實際處理使用者請求的持續時間。
- *排隊延遲*可以在流程的幾個點出現：例如，接收到請求後
- *延遲* 是一個包羅永珍的術語，用於描述請求未被積極處理的時間，即處於 *潛伏狀態* 的時間。特別是，*網路延遲* 或 *網路延遲* 指的是請求和響應在網路中傳輸的時間。

“Latency” and “response time” are sometimes used interchangeably, but in this book we will use the terms in a specific way (illustrated in [Figure 2-4](ch02.html#fig_response_time)):

- The *response time* is what the client sees; it includes all delays incurred anywhere in the system.
- The *service time* is the duration for which the service is actively processing the user request.
- *Queueing delays* can occur at several points in the flow: for example, after a request is received, it might need to wait until a CPU is available before it can be processed; a response packet might need to be buffered before it is sent over the network if other tasks on the same machine are sending a lot of data via the outbound network interface.
- *Latency* is a catch-all term for time during which a request is not being actively processed, i.e., during which it is *latent*. In particular, *network latency* or *network delay* refers to the time that request and response spend traveling through the network.

![ddia 0104a](../img/ddia_0104a.png)

> 圖2-4. 響應時間、服務時間、網路延遲和排隊延遲

即使反覆發出同一請求，響應時間也可能因請求而異，差異顯著。許多因素可能會導致隨機延遲：例如，切換到後臺程序的上下文切換，網路資料包丟失和 TCP 重傳，垃圾收集暫停，頁面錯誤強制從磁碟讀取，伺服器架的機械振動[[15](ch02.html#Gunawi2018)]，或許多其他原因。我們將在 [未來連結] 中更詳細地討論這個話題。

排隊延遲通常是響應時間變化性的一個重要部分。由於伺服器同時只能處理少量事務（例如，受其 CPU 核心數量的限制），只需少數幾個慢請求就足以阻塞後續請求的處理——這種效應被稱為 *隊首阻塞*。即使那些後續請求的服務時間很快，客戶端也會因為等待先前請求完成而感覺到整體響應時間的緩慢。排隊延遲不屬於服務時間的一部分，因此在客戶端測量響應時間十分重要。

The response time can vary significantly from one request to the next, even if you keep making the same request over and over again. Many factors can add random delays: for example, a context switch to a background process, the loss of a network packet and TCP retransmission, a garbage collection pause, a page fault forcing a read from disk, mechanical vibrations in the server rack [[15](ch02.html#Gunawi2018)], or many other causes. We will discuss this topic in more detail in [Link to Come].

Queueing delays often account for a large part of the variability in response times. As a server can only process a small number of things in parallel (limited, for example, by its number of CPU cores), it only takes a small number of slow requests to hold up the processing of subsequent requests—an effect known as *head-of-line blocking*. Even if those subsequent requests have fast service times, the client will see a slow overall response time due to the time waiting for the prior request to complete. The queueing delay is not part of the service time, and for this reason it is important to measure response times on the client side.

### 平均數，中位數與百分位點

因為響應時間從一個請求到另一個請求都在變化，我們需要把它視為一個你可以測量的值的 *分佈*，而不是一個單一的數字。在 [圖 2-5](ch02.html#fig_lognormal)，每個灰色條代表對一個服務的請求，其高度顯示了該請求所需的時間。大多數請求相當快，但偶爾也有 *異常值* 花費的時間要長得多。網路延遲的變化也被稱為 *抖動*。

Because the response time varies from one request to the next, we need to think of it not as a single number, but as a *distribution* of values that you can measure. In [Figure 2-5](ch02.html#fig_lognormal), each gray bar represents a request to a service, and its height shows how long that request took. Most requests are reasonably fast, but there are occasional *outliers* that take much longer. Variation in network delay is also known as *jitter*.

![ddia 0104](../img/ddia_0104.png)

> 圖 2-5. 描述平均值和百分位數：對某服務100次請求的響應時間。
>
> Figure 2-5. Illustrating mean and percentiles: response times for a sample of 100 requests to a service.

通常我們會報告服務的*平均*響應時間（技術上說是*算術平均值*：即總和所有的響應時間，然後除以請求的數量）。然而，如果你想了解你的“典型”響應時間，平均值並不是一個很好的度量，因為它不能告訴你有多少使用者實際經歷了那種延遲。

通常使用*百分位數*會更好。如果你將響應時間列表從最快到最慢排序，那麼*中位數*是中間點：例如，如果你的中位響應時間是200毫秒，這意味著你一半的請求在200毫秒內返回，另一半請求需要超過這個時間。這使得中位數成為一個好的度量，如果你想知道使用者通常需要等待多久。中位數也被稱為*第50百分位*，有時縮寫為*p50*。

為了弄清楚你的異常值有多嚴重，你可以檢視更高的百分位數：*第95、第99和第99.9百分位*是常見的（縮寫為*p95、p99和p999*）。它們是響應時間的閾值，即95%、99%或99.9%的請求比該特定閾值快。例如，如果第95百分位的響應時間是1.5秒，這意味著100次請求中有95次不到1.5秒，有5次需要1.5秒或更多時間。這在[圖 2-5](ch02.html#fig_lognormal)中有所示。

響應時間的高百分位數，也稱為*尾部延遲*，很重要，因為它們直接影響使用者對服務的體驗。例如，亞馬遜描述其內部服務的響應時間要求是以第99.9百分位來衡量，儘管它隻影響1/1000的請求。這是因為請求最慢的客戶往往是那些在他們的賬戶上有最多資料的客戶，因為他們進行了許多購買——即，他們是最有價值的客戶[[16](ch02.html#DeCandia2007_ch1)]。保證網站對他們來說快速是很重要的，以保持這些客戶的滿意。

另一方面，最佳化第99.99百分位（最慢的1/10,000的請求）被認為過於昂貴且對亞馬遜的目的來說收益不足。在非常高的百分位數上減少響應時間是困難的，因為它們容易受到你無法控制的隨機事件的影響，而且收益遞減。


It’s common to report the *average* response time of a service (technically, the *arithmetic mean*: that is, sum all the response times, and divide by the number of requests). However, the mean is not a very good metric if you want to know your “typical” response time, because it doesn’t tell you how many users actually experienced that delay.

Usually it is better to use *percentiles*. If you take your list of response times and sort it from fastest to slowest, then the *median* is the halfway point: for example, if your median response time is 200 ms, that means half your requests return in less than 200 ms, and half your requests take longer than that. This makes the median a good metric if you want to know how long users typically have to wait. The median is also known as the *50th percentile*, and sometimes abbreviated as *p50*.

In order to figure out how bad your outliers are, you can look at higher percentiles: the *95th*, *99th*, and *99.9th* percentiles are common (abbreviated *p95*, *p99*, and *p999*). They are the response time thresholds at which 95%, 99%, or 99.9% of requests are faster than that particular threshold. For example, if the 95th percentile response time is 1.5 seconds, that means 95 out of 100 requests take less than 1.5 seconds, and 5 out of 100 requests take 1.5 seconds or more. This is illustrated in [Figure 2-5](ch02.html#fig_lognormal).

High percentiles of response times, also known as *tail latencies*, are important because they directly affect users’ experience of the service. For example, Amazon describes response time requirements for internal services in terms of the 99.9th percentile, even though it only affects 1 in 1,000 requests. This is because the customers with the slowest requests are often those who have the most data on their accounts because they have made many purchases—that is, they’re the most valuable customers [[16](ch02.html#DeCandia2007_ch1)]. It’s important to keep those customers happy by ensuring the website is fast for them.

On the other hand, optimizing the 99.99th percentile (the slowest 1 in 10,000 requests) was deemed too expensive and to not yield enough benefit for Amazon’s purposes. Reducing response times at very high percentiles is difficult because they are easily affected by random events outside of your control, and the benefits are diminishing.

### 響應時間對使用者的影響

直覺上看，快速服務比慢服務更有利於使用者似乎是顯而易見的[[17](ch02.html#Whitenton2020)]。然而，要獲取可靠資料來量化延遲對使用者行為的影響卻出奇地困難。

一些經常被引用的統計資料是不可靠的。2006年穀歌報告稱，搜尋結果從400毫秒減慢到900毫秒，導致流量和收入下降20%[[18](ch02.html#Linden2006)]。然而，谷歌在2009年的另一項研究報告稱，延遲增加400毫秒僅導致每天的搜尋量減少0.6%[[19](ch02.html#Brutlag2009)]，同年必應發現載入時間增加兩秒鐘，廣告收入減少了4.3%[[20](ch02.html#Schurman2009)]。這些公司的更新資料似乎沒有公開。

Akamai的一項較新研究[[21](ch02.html#Akamai2017)]聲稱響應時間增加100毫秒，會使電子商務網站的轉化率降低多達7%；然而，仔細檢查同一研究發現，非常*快*的頁面載入時間也與較低的轉化率相關！這種看似矛盾的結果是由於最快載入的頁面往往是那些沒有有用內容的頁面（例如，404錯誤頁面）。然而，由於該研究沒有努力區分頁面內容和載入時間的影響，其結果可能沒有意義。

雅虎的一項研究[[22](ch02.html#Bai2017)]比較了快速載入與慢速載入搜尋結果的點選率，控制搜尋結果的質量。研究發現，當快速和慢速響應之間的差異在1.25秒或更多時，快速搜尋的點選率增加了20-30%。

It seems intuitively obvious that a fast service is better for users than a slow service [[17](ch02.html#Whitenton2020)]. However, it is surprisingly difficult to get hold of reliable data to quantify the effect that latency has on user behavior.

Some often-cited statistics are unreliable. In 2006 Google reported that a slowdown in search results from 400 ms to 900 ms was associated with a 20% drop in traffic and revenue [[18](ch02.html#Linden2006)]. However, another Google study from 2009 reported that a 400 ms increase in latency resulted in only 0.6% fewer searches per day [[19](ch02.html#Brutlag2009)], and in the same year Bing found that a two-second increase in load time reduced ad revenue by 4.3% [[20](ch02.html#Schurman2009)]. Newer data from these companies appears not to be publicly available.

A more recent Akamai study [[21](ch02.html#Akamai2017)] claims that a 100 ms increase in response time reduced the conversion rate of e-commerce sites by up to 7%; however, on closer inspection, the same study reveals that very *fast* page load times are also correlated with lower conversion rates! This seemingly paradoxical result is explained by the fact that the pages that load fastest are often those that have no useful content (e.g., 404 error pages). However, since the study makes no effort to separate the effects of page content from the effects of load time, its results are probably not meaningful.

A study by Yahoo [[22](ch02.html#Bai2017)] compares click-through rates on fast-loading versus slow-loading search results, controlling for quality of search results. It finds 20–30% more clicks on fast searches when the difference between fast and slow responses is 1.25 seconds or more.

#### 使用響應時間指標

高百分位數在後端服務中尤其重要，這些服務在處理單個終端使用者請求時會被多次呼叫。即使你並行進行呼叫，終端使用者請求仍然需要等待並行呼叫中最慢的一個完成。正如[圖 2-6](ch02.html#fig_tail_amplification)所示，只需一個慢呼叫就能使整個終端使用者請求變慢。即使只有少數後端呼叫較慢，如果終端使用者請求需要多次後端呼叫，獲得慢呼叫的機率就會增加，因此更高比例的終端使用者請求最終變慢（這種效應被稱為*尾延遲放大*[[23](ch02.html#Dean2013)]）。

High percentiles are especially important in backend services that are called multiple times as part of serving a single end-user request. Even if you make the calls in parallel, the end-user request still needs to wait for the slowest of the parallel calls to complete. It takes just one slow call to make the entire end-user request slow, as illustrated in [Figure 2-6](ch02.html#fig_tail_amplification). Even if only a small percentage of backend calls are slow, the chance of getting a slow call increases if an end-user request requires multiple backend calls, and so a higher proportion of end-user requests end up being slow (an effect known as *tail latency amplification* [[23](ch02.html#Dean2013)]).

![ddia 0105](../img/ddia_0105.png)

> 圖 2-6. 當一個請求需要多次後端呼叫時，只需要一個緩慢的後端請求，就能拖慢整個終端使用者的請求

百分位數通常用於*服務級別目標*（SLOs）和*服務級別協議*（SLAs），作為定義服務預期效能和可用性的方式[[24](ch02.html#Hidalgo2020)]。例如，SLO可能設定一個目標，要求服務的中位響應時間少於200毫秒，第99百分位在1秒以下，並且至少99.9%的有效請求結果為非錯誤響應。SLA是一份合同，規定如果未達到SLO將發生什麼（例如，客戶可能有權獲得退款）。至少基本思想是這樣的；實際上，為SLOs和SLAs定義良好的可用性指標並不簡單[[25](ch02.html#Mogul2019), 26]。

Percentiles are often used in *service level objectives* (SLOs) and *service level agreements* (SLAs) as ways of defining the expected performance and availability of a service [[24](ch02.html#Hidalgo2020)]. For example, an SLO may set a target for a service to have a median response time of less than 200 ms and a 99th percentile under 1 s, and a target that at least 99.9% of valid requests result in non-error responses. An SLA is a contract that specifies what happens if the SLO is not met (for example, customers may be entitled to a refund). That is the basic idea, at least; in practice, defining good availability metrics for SLOs and SLAs is not straightforward [[25](ch02.html#Mogul2019), [26](ch02.html#Hauer2020)].

#### 計算百分位點

如果你想在服務的監控儀表板上新增響應時間百分位數，你需要持續有效地計算它們。例如，你可能希望保持一個最近10分鐘內請求響應時間的滾動視窗。每分鐘，你都會計算該視窗中的中位數和各種百分位數，並將這些指標繪製在圖表上。

最簡單的實現方式是保留時間視窗內所有請求的響應時間列表，並每分鐘對該列表進行排序。如果這對你來說效率太低，有些演算法可以以最小的CPU和記憶體成本計算出百分位數的良好近似值。開源的百分位數估計庫包括 HdrHistogram、t-digest [[27](ch02.html#Dunning2021), [28](ch02.html#Kohn2021)]、OpenHistogram [[29](ch02.html#Hartmann2020)] 和 DDSketch [[30](ch02.html#Masson2019)]。

注意，對百分位數進行平均化，例如為了降低時間解析度或將來自幾臺機器的資料結合在一起，從數學上講是沒有意義的——聚合響應時間資料的正確方法是新增直方圖[[31](ch02.html#Schwartz2015)]。

If you want to add response time percentiles to the monitoring dashboards for your services, you need to efficiently calculate them on an ongoing basis. For example, you may want to keep a rolling window of response times of requests in the last 10 minutes. Every minute, you calculate the median and various percentiles over the values in that window and plot those metrics on a graph.

The simplest implementation is to keep a list of response times for all requests within the time window and to sort that list every minute. If that is too inefficient for you, there are algorithms that can calculate a good approximation of percentiles at minimal CPU and memory cost. Open source percentile estimation libraries include HdrHistogram, t-digest [[27](ch02.html#Dunning2021), [28](ch02.html#Kohn2021)], OpenHistogram [[29](ch02.html#Hartmann2020)], and DDSketch [[30](ch02.html#Masson2019)].

Beware that averaging percentiles, e.g., to reduce the time resolution or to combine data from several machines, is mathematically meaningless—the right way of aggregating response time data is to add the histograms [[31](ch02.html#Schwartz2015)].



--------

## 可靠性與容錯

每個人對於一個東西可靠不可靠都有自己的直觀想法。對於軟體來說，典型的期望包括：

* 應用程式表現出使用者所期望的功能。
* 軟體允許使用者犯錯，或以意料之外的方式來使用軟體。
* 在預期的負載和資料量下，效能可以滿足要求。
* 系統能夠阻止未經授權的訪問和濫用。

如果把所有這些要求放一塊兒意味著 “正確工作”，那麼我們可以把 *可靠性* 粗略理解為：“即使出現問題，也能繼續正常工作”。為了更準確地描述問題的發生，我們將區分*故障*和*失敗*[[32](ch02.html#Heimerdinger1992), [33](ch02.html#Gaertner1999)]：

- **故障**（fault）

  故障是指系統的某個部分停止正常工作：例如，單個硬碟故障，或者單臺機器崩潰，或者系統依賴的外部服務出現中斷。
  A fault is when a particular *part* of a system stops working correctly: for example, if a single hard drive malfunctions, or a single machine crashes, or an external service (that the system depends on) has an outage.

- **失效**（Failure）

  失效是指系統整體停止向用戶提供所需服務；換句話說，就是未達到服務級別目標（SLO）。
  A failure is when the system *as a whole* stops providing the required service to the user; in other words, when it does not meet the service level objective (SLO).

故障與失敗之間的區別可能會引起混淆，因為它們是同一件事，只是在不同的層級上。例如，如果一個硬碟停止工作，我們說硬碟發生了失敗：如果系統只由那一個硬碟組成，它就停止提供所需的服務。然而，如果你所說的系統包含多個硬碟，那麼單個硬碟的失敗只是從更大系統的角度看是一個故障，並且更大的系統可能能夠透過在另一個硬碟上有資料的副本來容忍這個故障。

The distinction between fault and failure can be confusing because they are the same thing, just at different levels. For example, if a hard drive stops working, we say that the hard drive has failed: if the system consists only of that one hard drive, it has stopped providing the required service. However, if the system you’re talking about contains many hard drives, then the failure of a single hard drive is only a fault from the point of view of the bigger system, and the bigger system might be able to tolerate that fault by having a copy of the data on another hard drive.


### 容錯

如果系統在某些故障發生時仍繼續向用戶提供所需服務，我們稱該系統為*容錯*系統。如果系統不能容忍某部分出現故障，我們稱該部分為*單點故障*（SPOF），因為該部分的故障會升級為導致整個系統的失敗。

例如，在社交網路案例研究中，可能發生的故障是在廣播過程中，參與更新物化時間線的機器崩潰或變得不可用。為了使這個過程具有容錯性，我們需要確保另一臺機器能夠接管這個任務，不遺漏任何本應傳送的帖子，也不重複任何帖子。（這個概念被稱為*精確一次語義*，我們將在[未來連結]中詳細討論）

We call a system *fault-tolerant* if it continues providing the required service to the user in spite of certain faults occurring. If a system cannot tolerate a certain part becoming faulty, we call that part a *single point of failure* (SPOF), because a fault in that part escalates to cause the failure of the whole system.

For example, in the social network case study, a fault that might happen is that during the fan-out process, a machine involved in updating the materialized timelines crashes or become unavailable. To make this process fault-tolerant, we would need to ensure that another machine can take over this task without missing any posts that should have been delivered, and without duplicating any posts. (This idea is known as *exactly-once semantics*, and we will examine it in detail in [Link to Come].)

容錯性始終僅限於一定數量的特定型別的故障。例如，一個系統可能能夠同時容忍最多兩個硬碟故障，或者三個節點中最多有一個崩潰。容忍任意數量的故障是沒有意義的：如果所有節點都崩潰了，那就無計可施。如果整個地球（及其上的所有伺服器）被黑洞吞噬，那麼要容忍這種故障就需要在太空中進行網路託管——祝你好運，讓這個預算專案獲批。

違反直覺的是，在這樣的容錯系統中，透過故意觸發故障來*增加*故障率是有意義的——例如，隨機無預警地終止個別程序。許多關鍵性的錯誤實際上是由於錯誤處理不當引起的[[34](ch02.html#Yuan2014)]；透過故意誘發故障，你確保了容錯機制不斷地得到運用和測試，這可以增強你的信心，相信在自然發生故障時能夠得到正確處理。*混沌工程*是一門旨在透過諸如故意注入故障的實驗來提高對容錯機制信心的學科[[35](ch02.html#Rosenthal2020)]。

雖然我們通常傾向於容忍故障而非預防故障，但在某些情況下，預防比治療更好（例如，因為沒有治療方法）。在安全問題上就是這樣，例如：如果攻擊者已經侵入系統並獲取了敏感資料，那個事件是無法撤銷的。然而，本書主要討論的是可以治癒的故障型別，如下文所述。

Fault tolerance is always limited to a certain number of certain types of faults. For example, a system might be able to tolerate a maximum of two hard drives failing at the same time, or a maximum of one out of three nodes crashing. It would not make sense to tolerate any number of faults: if all nodes crash, there is nothing that can be done. If the entire planet Earth (and all servers on it) were swallowed by a black hole, tolerance of that fault would require web hosting in space—good luck getting that budget item approved.

Counter-intuitively, in such fault-tolerant systems, it can make sense to *increase* the rate of faults by triggering them deliberately—for example, by randomly killing individual processes without warning. Many critical bugs are actually due to poor error handling [[34](ch02.html#Yuan2014)]; by deliberately inducing faults, you ensure that the fault-tolerance machinery is continually exercised and tested, which can increase your confidence that faults will be handled correctly when they occur naturally. *Chaos engineering* is a discipline that aims to improve confidence in fault-tolerance mechanisms through experiments such as deliberately injecting faults [[35](ch02.html#Rosenthal2020)].

Although we generally prefer tolerating faults over preventing faults, there are cases where prevention is better than cure (e.g., because no cure exists). This is the case with security matters, for example: if an attacker has compromised a system and gained access to sensitive data, that event cannot be undone. However, this book mostly deals with the kinds of faults that can be cured, as described in the following sections.

### 硬體與軟體缺陷

當我們思考系統故障的原因時，硬體故障很快浮現腦海：

- 每年大約有 2-5% 的磁碟硬碟出現故障[[36](ch02.html#Pinheiro2007), [37](ch02.html#Schroeder2007)]；在一個擁有 10,000 塊硬碟的儲存叢集中，我們因此可以預計平均每天會有一塊硬碟故障。最近的資料表明硬碟越來越可靠，但故障率仍然顯著[[38](ch02.html#Klein2021)]。
- 每年大約有 0.5-1% 的固態硬碟（SSD）故障[[39](ch02.html#Narayanan2016)]。少量的位錯誤可以自動糾正[[40](ch02.html#Alibaba2019_ch2)]，但不可糾正的錯誤大約每年每塊硬碟發生一次，即使是相當新的硬碟（即，磨損較少的硬碟）；這種錯誤率高於磁碟硬碟[[41](ch02.html#Schroeder2016), [42](ch02.html#Alter2019)]。
- 其他硬體元件如電源供應器、RAID 控制器和記憶體模組也會發生故障，儘管頻率低於硬碟[[43](ch02.html#Ford2010), [44](ch02.html#Vishwanath2010)]。
- 大約每 1,000 臺機器中就有一臺的 CPU 核心偶爾計算出錯誤的結果，這很可能是由製造缺陷引起的[[45](ch02.html#Hochschild2021), [46](ch02.html#Dixit2021), [47](ch02.html#Behrens2015)]。在某些情況下，錯誤的計算會導致崩潰，但在其他情況下，它會導致程式簡單地返回錯誤的結果。
- RAM 中的資料也可能被破壞，原因可能是宇宙射線等隨機事件，或是永久性物理缺陷。即使使用了具有糾錯碼（ECC）的記憶體，超過 1% 的機器在給定年份遇到不可糾正的錯誤，這通常會導致機器和受影響的記憶體模組崩潰並需要更換[[48](ch02.html#Schroeder2009)]。此外，某些病態的記憶體訪問模式可以高機率地翻轉位[[49](ch02.html#Kim2014)]。
- 整個資料中心可能變得不可用（例如，由於停電或網路配置錯誤）或甚至被永久性破壞（例如火災或洪水）。儘管這種大規模故障很少見，但如果一項服務不能容忍資料中心的丟失，其影響可能是災難性的[[50](ch02.html#Cockcroft2019)]。

這些事件足夠罕見，以至於在處理小型系統時你通常不需要擔心它們，只要你可以輕鬆替換變得有故障的硬體。然而，在大規模系統中，硬體故障發生得足夠頻繁，以至於它們成為正常系統運作的一部分。

When we think of causes of system failure, hardware faults quickly come to mind:

- Approximately 2–5% of magnetic hard drives fail per year [[36](ch02.html#Pinheiro2007), [37](ch02.html#Schroeder2007)]; in a storage cluster with 10,000 disks, we should therefore expect on average one disk failure per day. Recent data suggests that disks are getting more reliable, but failure rates remain significant [[38](ch02.html#Klein2021)].
- Approximately 0.5–1% of solid state drives (SSDs) fail per year [[39](ch02.html#Narayanan2016)]. Small numbers of bit errors are corrected automatically [[40](ch02.html#Alibaba2019_ch2)], but uncorrectable errors occur approximately once per year per drive, even in drives that are fairly new (i.e., that have experienced little wear); this error rate is higher than that of magnetic hard drives [[41](ch02.html#Schroeder2016), [42](ch02.html#Alter2019)].
- Other hardware components such as power supplies, RAID controllers, and memory modules also fail, although less frequently than hard drives [[43](ch02.html#Ford2010), [44](ch02.html#Vishwanath2010)].
- Approximately one in 1,000 machines has a CPU core that occasionally computes the wrong result, likely due to manufacturing defects [[45](ch02.html#Hochschild2021), [46](ch02.html#Dixit2021), [47](ch02.html#Behrens2015)]. In some cases, an erroneous computation leads to a crash, but in other cases it leads to a program simply returning the wrong result.
- Data in RAM can also be corrupted, either due to random events such as cosmic rays, or due to permanent physical defects. Even when memory with error-correcting codes (ECC) is used, more than 1% of machines encounter an uncorrectable error in a given year, which typically leads to a crash of the machine and the affected memory module needing to be replaced [[48](ch02.html#Schroeder2009)]. Moreover, certain pathological memory access patterns can flip bits with high probability [[49](ch02.html#Kim2014)].
- An entire datacenter might become unavailable (for example, due to power outage or network misconfiguration) or even be permanently destroyed (for example by fire or flood). Although such large-scale failures are rare, their impact can be catastrophic if a service cannot tolerate the loss of a datacenter [[50](ch02.html#Cockcroft2019)].

These events are rare enough that you often don’t need to worry about them when working on a small system, as long as you can easily replace hardware that becomes faulty. However, in a large-scale system, hardware faults happen often enough that they become part of the normal system operation.

#### 透過冗餘容忍硬體缺陷

Our first response to unreliable hardware is usually to add redundancy to the individual hardware components in order to reduce the failure rate of the system. Disks may be set up in a RAID configuration (spreading data across multiple disks in the same machine so that a failed disk does not cause data loss), servers may have dual power supplies and hot-swappable CPUs, and datacenters may have batteries and diesel generators for backup power. Such redundancy can often keep a machine running uninterrupted for years.

Redundancy is most effective when component faults are independent, that is, the occurrence of one fault does not change how likely it is that another fault will occur. However, experience has shown that there are often significant correlations between component failures [[37](ch02.html#Schroeder2007), [51](ch02.html#Han2021), [52](ch02.html#Nightingale2011)]; unavailability of an entire server rack or an entire datacenter still happens more often than we would like.

Hardware redundancy increases the uptime of a single machine; however, as discussed in [“Distributed versus Single-Node Systems”](ch01.html#sec_introduction_distributed), there are advantages to using a distributed system, such as being able to tolerate a complete outage of one datacenter. For this reason, cloud systems tend to focus less on the reliability of individual machines, and instead aim to make services highly available by tolerating faulty nodes at the software level. Cloud providers use *availability zones* to identify which resources are physically co-located; resources in the same place are more likely to fail at the same time than geographically separated resources.

The fault-tolerance techniques we discuss in this book are designed to tolerate the loss of entire machines, racks, or availability zones. They generally work by allowing a machine in one datacenter to take over when a machine in another datacenter fails or becomes unreachable. We will discuss such techniques for fault tolerance in [Link to Come], [Link to Come], and at various other points in this book.

Systems that can tolerate the loss of entire machines also have operational advantages: a single-server system requires planned downtime if you need to reboot the machine (to apply operating system security patches, for example), whereas a multi-node fault-tolerant system can be patched by restarting one node at a time, without affecting the service for users. This is called a *rolling upgrade*, and we will discuss it further in [Link to Come].

#### 軟體缺陷

我們通常認為硬體故障是隨機的、相互獨立的：一臺機器的磁碟失效並不意味著另一臺機器的磁碟也會失效。雖然大量硬體元件之間可能存在微弱的相關性（例如伺服器機架的溫度等共同的原因），但同時發生故障也是極為罕見的。

另一類錯誤是內部的 **系統性錯誤（systematic error）**【8】。這類錯誤難以預料，而且因為是跨節點相關的，所以比起不相關的硬體故障往往可能造成更多的 **系統失效**【5】。例子包括：

* 接受特定的錯誤輸入，便導致所有應用伺服器例項崩潰的 BUG。例如 2012 年 6 月 30 日的閏秒，由於 Linux 核心中的一個錯誤【9】，許多應用同時掛掉了。
* 失控程序會用盡一些共享資源，包括 CPU 時間、記憶體、磁碟空間或網路頻寬。
* 系統依賴的服務變慢，沒有響應，或者開始返回錯誤的響應。
* 級聯故障，一個元件中的小故障觸發另一個元件中的故障，進而觸發更多的故障【10】。

導致這類軟體故障的 BUG 通常會潛伏很長時間，直到被異常情況觸發為止。這種情況意味著軟體對其環境做出了某種假設 —— 雖然這種假設通常來說是正確的，但由於某種原因最後不再成立了【11】。

雖然軟體中的系統性故障沒有速效藥，但我們還是有很多小辦法，例如：仔細考慮系統中的假設和互動；徹底的測試；程序隔離；允許程序崩潰並重啟；測量、監控並分析生產環境中的系統行為。如果系統能夠提供一些保證（例如在一個訊息佇列中，進入與發出的訊息數量相等），那麼系統就可以在執行時不斷自檢，並在出現 **差異（discrepancy）** 時報警【12】。


Although hardware failures can be weakly correlated, they are still mostly independent: for example, if one disk fails, it’s likely that other disks in the same machine will be fine for another while. On the other hand, software faults are often very highly correlated, because it is common for many nodes to run the same software and thus have the same bugs [[53](ch02.html#Gunawi2014), [54](ch02.html#Kreps2012_ch1)]. Such faults are harder to anticipate, and they tend to cause many more system failures than uncorrelated hardware faults [[43](ch02.html#Ford2010)]. For example:

- A software bug that causes every node to fail at the same time in particular circumstances. For example, on June 30, 2012, a leap second caused many Java applications to hang simultaneously due to a bug in the Linux kernel, bringing down many Internet services [[55](ch02.html#Minar2012_ch1)]. Due to a firmware bug, all SSDs of certain models suddenly fail after precisely 32,768 hours of operation (less than 4 years), rendering the data on them unrecoverable [[56](ch02.html#HPE2019)].
- A runaway process that uses up some shared, limited resource, such as CPU time, memory, disk space, network bandwidth, or threads [[57](ch02.html#Hochstein2020)]. For example, a process that consumes too much memory while processing a large request may be killed by the operating system.
- A service that the system depends on slows down, becomes unresponsive, or starts returning corrupted responses.
- An interaction between different systems results in emergent behavior that does not occur when each system was tested in isolation [[58](ch02.html#Tang2023)].
- Cascading failures, where a problem in one component causes another component to become overloaded and slow down, which in turn brings down another component [[59](ch02.html#Ulrich2016), [60](ch02.html#Fassbender2022)].

The bugs that cause these kinds of software faults often lie dormant for a long time until they are triggered by an unusual set of circumstances. In those circumstances, it is revealed that the software is making some kind of assumption about its environment—and while that assumption is usually true, it eventually stops being true for some reason [[61](ch02.html#Cook2000), [62](ch02.html#Woods2017)].

There is no quick solution to the problem of systematic faults in software. Lots of small things can help: carefully thinking about assumptions and interactions in the system; thorough testing; process isolation; allowing processes to crash and restart; avoiding feedback loops such as retry storms (see [“When an overloaded system won’t recover”](ch02.html#sidebar_metastable)); measuring, monitoring, and analyzing system behavior in production.

### 人類與可靠性

設計並構建了軟體系統的工程師是人類，維持系統執行的運維也是人類。即使他們懷有最大的善意，人類也是不可靠的。舉個例子，一項關於大型網際網路服務的研究發現，運維配置錯誤是導致服務中斷的首要原因，而硬體故障（伺服器或網路）僅導致了 10-25% 的服務中斷【13】。

儘管人類不可靠，但怎麼做才能讓系統變得可靠？最好的系統會組合使用以下幾種辦法：

* 以最小化犯錯機會的方式設計系統。例如，精心設計的抽象、API 和管理後臺使做對事情更容易，搞砸事情更困難。但如果介面限制太多，人們就會忽略它們的好處而想辦法繞開。很難正確把握這種微妙的平衡。
* 將人們最容易犯錯的地方與可能導致失效的地方 **解耦（decouple）**。特別是提供一個功能齊全的非生產環境 **沙箱（sandbox）**，使人們可以在不影響真實使用者的情況下，使用真實資料安全地探索和實驗。
* 在各個層次進行徹底的測試【3】，從單元測試、全系統整合測試到手動測試。自動化測試易於理解，已經被廣泛使用，特別適合用來覆蓋正常情況中少見的 **邊緣場景（corner case）**。
* 允許從人為錯誤中簡單快速地恢復，以最大限度地減少失效情況帶來的影響。例如，快速回滾配置變更，分批發布新程式碼（以便任何意外錯誤隻影響一小部分使用者），並提供資料重算工具（以備舊的計算出錯）。
* 配置詳細和明確的監控，比如效能指標和錯誤率。在其他工程學科中這指的是 **遙測（telemetry）**（一旦火箭離開了地面，遙測技術對於跟蹤發生的事情和理解失敗是至關重要的）。監控可以向我們發出預警訊號，並允許我們檢查是否有任何地方違反了假設和約束。當出現問題時，指標資料對於問題診斷是非常寶貴的。
* 良好的管理實踐與充分的培訓 —— 一個複雜而重要的方面，但超出了本書的範圍。


Humans design and build software systems, and the operators who keep the systems running are also human. Unlike machines, humans don’t just follow rules; their strength is being creative and adaptive in getting their job done. However, this characteristic also leads to unpredictability, and sometimes mistakes that can lead to failures, despite best intentions. For example, one study of large internet services found that configuration changes by operators were the leading cause of outages, whereas hardware faults (servers or network) played a role in only 10–25% of outages [[63](ch02.html#Oppenheimer2003)].

It is tempting to label such problems as “human error” and to wish that they could be solved by better controlling human behavior through tighter procedures and compliance with rules. However, blaming people for mistakes is counterproductive. What we call “human error” is not really the cause of an incident, but rather a symptom of a problem with the sociotechnical system in which people are trying their best to do their jobs [[64](ch02.html#Dekker2017)].

Various technical measures can help minimize the impact of human mistakes, including thorough testing [[34](ch02.html#Yuan2014)], rollback mechanisms for quickly reverting configuration changes, gradual roll-outs of new code, detailed and clear monitoring, observability tools for diagnosing production issues (see [“Problems with Distributed Systems”](ch01.html#sec_introduction_dist_sys_problems)), and well-designed interfaces that encourage “the right thing” and discourage “the wrong thing”.

However, these things require an investment of time and money, and in the pragmatic reality of everyday business, organizations often prioritize revenue-generating activities over measures that increase their resilience against mistakes. If there is a choice between more features and more testing, many organizations understandably choose features. Given this choice, when a preventable mistake inevitably occurs, it does not make sense to blame the person who made the mistake—the problem is the organization’s priorities.

Increasingly, organizations are adopting a culture of *blameless postmortems*: after an incident, the people involved are encouraged to share full details about what happened, without fear of punishment, since this allows others in the organization to learn how to prevent similar problems in the future [[65](ch02.html#Allspaw2012)]. This process may uncover a need to change business priorities, a need to invest in areas that have been neglected, a need to change the incentives for the people involved, or some other systemic issue that needs to be brought to the management’s attention.

As a general principle, when investigating an incident, you should be suspicious of simplistic answers. “Bob should have been more careful when deploying that change” is not productive, but neither is “We must rewrite the backend in Haskell.” Instead, management should take the opportunity to learn the details of how the sociotechnical system works from the point of view of the people who work with it every day, and take steps to improve it based on this feedback [[64](ch02.html#Dekker2017)].

### 可靠性到底有多重要？

可靠性不僅僅是針對核電站和空中交通管制軟體而言，我們也期望更多平凡的應用能可靠地執行。商務應用中的錯誤會導致生產力損失（也許資料報告不完整還會有法律風險），而電商網站的中斷則可能會導致收入和聲譽的巨大損失。

即使在 “非關鍵” 應用中，我們也對使用者負有責任。試想一位家長把所有的照片和孩子的影片儲存在你的照片應用裡【15】。如果資料庫突然損壞，他們會感覺如何？他們可能會知道如何從備份恢復嗎？

在某些情況下，我們可能會選擇犧牲可靠性來降低開發成本（例如為未經證實的市場開發產品原型）或運營成本（例如利潤率極低的服務），但我們偷工減料時，應該清楚意識到自己在做什麼。


Reliability is not just for nuclear power stations and air traffic control—more mundane applications are also expected to work reliably. Bugs in business applications cause lost productivity (and legal risks if figures are reported incorrectly), and outages of e-commerce sites can have huge costs in terms of lost revenue and damage to reputation.

In many applications, a temporary outage of a few minutes or even a few hours is tolerable [[66](ch02.html#Sabo2023)], but permanent data loss or corruption would be catastrophic. Consider a parent who stores all their pictures and videos of their children in your photo application [[67](ch02.html#Jurewitz2013)]. How would they feel if that database was suddenly corrupted? Would they know how to restore it from a backup?

As another example of how unreliable software can harm people, consider the Post Office Horizon scandal. Between 1999 and 2019, hundreds of people managing Post Office branches in Britain were convicted of theft or fraud because the accounting software showed a shortfall in their accounts. Eventually it became clear that many of these shortfalls were due to bugs in the software, and many convictions have since been overturned [[68](ch02.html#Siddique2021)]. What led to this, probably the largest miscarriage of justice in British history, is the fact that English law assumes that computers operate correctly (and hence, evidence produced by computers is reliable) unless there is evidence to the contrary [[69](ch02.html#Bohm2022)]. Software engineers may laugh at the idea that software could ever be bug-free, but this is little solace to the people who were wrongfully imprisoned, declared bankrupt, or even committed suicide as a result of a wrongful conviction due to an unreliable computer system.

There are situations in which we may choose to sacrifice reliability in order to reduce development cost (e.g., when developing a prototype product for an unproven market)—but we should be very conscious of when we are cutting corners and keep in mind the potential consequences.





--------

## 可伸縮性

即使系統今天執行可靠，也不意味著將來一定能保持可靠。退化的一個常見原因是負載增加：可能系統從1萬併發使用者增長到了10萬，併發使用者，或從100萬增加到了1000萬。也許它正在處理比以前更大的資料量。

可擴充套件性是我們用來描述系統應對增加負載能力的術語。有時，在討論可擴充套件性時，人們會這樣評論：“你不是谷歌或亞馬遜。不用擔心規模，只用關係型資料庫就好。”這個格言是否適用於你，取決於你正在構建的應用型別。

如果你正在為一個剛起步的公司構建一個新產品，目前只有少數使用者，通常最重要的工程目標是保持系統儘可能簡單和靈活，以便你可以根據對客戶需求的瞭解輕鬆修改和適應產品功能[70]。在這種環境下，擔心未來可能需要的假設性規模是適得其反的：在最好的情況下，投資於可擴充套件性是浪費努力和過早的最佳化；在最壞的情況下，它們會讓你陷入僵化的設計，使得應用難以進化。

原因是可擴充套件性不是一維標籤：說“X可擴充套件”或“Y不可擴充套件”是沒有意義的。相反，討論可擴充套件性意味著考慮諸如此類的問題：

“如果系統以特定方式增長，我們有哪些應對增長的選項？”
“我們如何增加計算資源來處理額外的負載？”
“基於當前的增長預測，我們何時會達到當前架構的極限？”
如果你成功地讓你的應用受歡迎，因此處理了越來越多的負載，你將瞭解你的效能瓶頸在哪裡，因此你將知道你需要沿哪些維度進行擴充套件。到了那個時候，就是開始擔心擴充套件技術的時候了。

Even if a system is working reliably today, that doesn’t mean it will necessarily work reliably in the future. One common reason for degradation is increased load: perhaps the system has grown from 10,000 concurrent users to 100,000 concurrent users, or from 1 million to 10 million. Perhaps it is processing much larger volumes of data than it did before.

*Scalability* is the term we use to describe a system’s ability to cope with increased load. Sometimes, when discussing scalability, people make comments along the lines of, “You’re not Google or Amazon. Stop worrying about scale and just use a relational database.” Whether this maxim applies to you depends on the type of application you are building.

If you are building a new product that currently only has a small number of users, perhaps at a startup, the overriding engineering goal is usually to keep the system as simple and flexible as possible, so that you can easily modify and adapt the features of your product as you learn more about customers’ needs [[70](ch02.html#McKinley2015)]. In such an environment, it is counterproductive to worry about hypothetical scale that might be needed in the future: in the best case, investments in scalability are wasted effort and premature optimization; in the worst case, they lock you into an inflexible design and make it harder to evolve your application.

The reason is that scalability is not a one-dimensional label: it is meaningless to say “X is scalable” or “Y doesn’t scale.” Rather, discussing scalability means considering questions like:

- “If the system grows in a particular way, what are our options for coping with the growth?”
- “How can we add computing resources to handle the additional load?”
- “Based on current growth projections, when will we hit the limits of our current architecture?”

If you succeed in making your application popular, and therefore handling a growing amount of load, you will learn where your performance bottlenecks lie, and therefore you will know along which dimensions you need to scale. At that point it’s time to start worrying about techniques for scalability.

### 描述負載

首先，我們需要簡潔地描述系統當前的負載；只有這樣，我們才能討論增長問題（如果我們的負載翻倍會發生什麼？）。這通常是透過吞吐量來衡量的：例如，每秒向服務的請求數量、每天新增多少吉位元組的資料，或者每小時有多少購物車結賬。有時你關心某些變數的峰值，比如同時線上使用者的數量，如[“案例研究：社交網路首頁時間線”](ch02.html#sec_introduction_twitter)中所述。

負載的其他統計特性也可能影響訪問模式，從而影響可擴充套件性需求。例如，你可能需要知道資料庫中讀寫的比例、快取的命中率，或每個使用者的資料項數量（例如，社交網路案例研究中的關注者數量）。也許平均情況是你關心的，或許你的瓶頸由少數極端情況主導。這一切都取決於你特定應用的細節。

一旦你描述了系統的負載，你就可以探究當負載增加時會發生什麼。你可以從兩個方面考慮這個問題：

- 當你以某種方式增加負載並保持系統資源（CPU、記憶體、網路頻寬等）不變時，你的系統性能會受到什麼影響？
- 當你以某種方式增加負載時，如果你想保持效能不變，你需要增加多少資源？

通常我們的目標是在最小化執行系統的成本的同時，保持系統性能符合SLA的要求（見[“響應時間指標的使用”](ch02.html#sec_introduction_slo_sla)）。所需的計算資源越多，成本就越高。可能某些型別的硬體比其他型別更具成本效益，隨著新型硬體的出現，這些因素可能會隨時間而變化。

如果你可以透過加倍資源來處理雙倍的負載，同時保持效能不變，我們就說你實現了*線性可擴充套件性*，這被認為是一件好事。偶爾也可能透過不到雙倍的資源來處理雙倍的負載，這得益於規模經濟或更好的高峰負載分配[[71](ch02.html#Warfield2023)，[72](ch02.html#Brooker2023)]。更常見的情況是，成本增長超過線性，可能有許多原因導致這種低效。例如，如果你有大量資料，那麼處理單個寫請求可能涉及的工作量比你的資料量小的時候要多，即使請求的大小相同。

First, we need to succinctly describe the current load on the system; only then can we discuss growth questions (what happens if our load doubles?). Often this will be a measure of throughput: for example, the number of requests per second to a service, how many gigabytes of new data arrive per day, or the number of shopping cart checkouts per hour. Sometimes you care about the peak of some variable quantity, such as the number of simultaneously online users in [“Case Study: Social Network Home Timelines”](ch02.html#sec_introduction_twitter).

Often there are other statistical characteristics of the load that also affect the access patterns and hence the scalability requirements. For example, you may need to know the ratio of reads to writes in a database, the hit rate on a cache, or the number of data items per user (for example, the number of followers in the social network case study). Perhaps the average case is what matters for you, or perhaps your bottleneck is dominated by a small number of extreme cases. It all depends on the details of your particular application.

Once you have described the load on your system, you can investigate what happens when the load increases. You can look at it in two ways:

- When you increase the load in a certain way and keep the system resources (CPUs, memory, network bandwidth, etc.) unchanged, how is the performance of your system affected?
- When you increase the load in a certain way, how much do you need to increase the resources if you want to keep performance unchanged?

Usually our goal is to keep the performance of the system within the requirements of the SLA (see [“Use of Response Time Metrics”](ch02.html#sec_introduction_slo_sla)) while also minimizing the cost of running the system. The greater the required computing resources, the higher the cost. It might be that some types of hardware are more cost-effective than others, and these factors may change over time as new types of hardware become available.

If you can double the resources in order to handle twice the load, while keeping performance the same, we say that you have *linear scalability*, and this is considered a good thing. Occasionally it is possible to handle twice the load with less than double the resources, due to economies of scale or a better distribution of peak load [[71](ch02.html#Warfield2023), [72](ch02.html#Brooker2023)]. Much more likely is that the cost grows faster than linearly, and there may be many reasons for the inefficiency. For example, if you have a lot of data, then processing a single write request may involve more work than if you have a small amount of data, even if the size of the request is the same.

### 共享記憶體，共享磁碟，無共享架構

增加服務的硬體資源最簡單的方式是將其遷移到更強大的機器上。單個CPU核心的速度不再顯著提升，但您可以購買（或租用雲實例）一個擁有更多CPU核心、更多RAM和更多磁碟空間的機器。這種方法被稱為*垂直擴充套件*或*向上擴充套件*。

在單臺機器上，您可以透過使用多個程序或執行緒來實現並行性。屬於同一程序的所有執行緒可以訪問同一RAM，因此這種方法也被稱為*共享記憶體架構*。共享記憶體方法的問題在於成本增長超過線性：擁有雙倍硬體資源的高階機器通常的成本顯著高於兩倍。而且由於瓶頸，一臺規模加倍的機器往往處理的負載不到兩倍。

另一種方法是*共享磁碟架構*，它使用多臺擁有獨立CPU和RAM的機器，但將資料儲存在一個磁碟陣列上，這些磁碟陣列在機器之間透過快速網路共享：*網路附加儲存*（NAS）或*儲存區域網路*（SAN）。這種架構傳統上用於本地資料倉庫工作負載，但爭用和鎖定開銷限制了共享磁碟方法的可擴充套件性[[73](ch02.html#Stopford2009)]。

相比之下，*無共享架構* [[74](ch02.html#Stonebraker1986)]（也稱為*水平擴充套件*或*向外擴充套件*）獲得了很大的流行。在這種方法中，我們使用一個具有多個節點的分散式系統，每個節點都擁有自己的CPU、RAM和磁碟。節點之間的任何協調都在軟體層面透過常規網路完成。

無共享的優勢在於它有潛力線性擴充套件，它可以使用提供最佳價格/效能比的任何硬體（特別是在雲中），它可以隨著負載的增減更容易地調整其硬體資源，並且透過在多個數據中心和地區分佈系統，它可以實現更大的容錯性。缺點是它需要顯式的資料分割槽（見[連結即將到來]），並且帶來了分散式系統的所有複雜性（見[連結即將到來]）。

一些雲原生資料庫系統使用獨立的服務來執行儲存和事務處理（見[“儲存與計算的分離”](ch01.html#sec_introduction_storage_compute)），多個計算節點共享訪問同一個儲存服務。這種模型與共享磁碟架構有些相似，但它避免了舊系統的可擴充套件性問題：儲存服務不提供檔案系統（NAS）或塊裝置（SAN）抽象，而是提供了專門為資料庫需求設計的專用API[[75](ch02.html#Antonopoulos2019_ch2)]。

The simplest way of increasing the hardware resources of a service is to move it to a more powerful machine. Individual CPU cores are no longer getting significantly faster, but you can buy a machine (or rent a cloud instance) with more CPU cores, more RAM, and more disk space. This approach is called *vertical scaling* or *scaling up*.

You can get parallelism on a single machine by using multiple processes or threads. All the threads belonging to the same process can access the same RAM, and hence this approach is also called a *shared-memory architecture*. The problem with a shared-memory approach is that the cost grows faster than linearly: a high-end machine with twice the hardware resources typically costs significantly more than twice as much. And due to bottlenecks, a machine twice the size can often handle less than twice the load.

Another approach is the *shared-disk architecture*, which uses several machines with independent CPUs and RAM, but which stores data on an array of disks that is shared between the machines, which are connected via a fast network: *Network-Attached Storage* (NAS) or *Storage Area Network* (SAN). This architecture has traditionally been used for on-premises data warehousing workloads, but contention and the overhead of locking limit the scalability of the shared-disk approach [[73](ch02.html#Stopford2009)].

By contrast, the *shared-nothing architecture* [[74](ch02.html#Stonebraker1986)] (also called *horizontal scaling* or *scaling out*) has gained a lot of popularity. In this approach, we use a distributed system with multiple nodes, each of which has its own CPUs, RAM, and disks. Any coordination between nodes is done at the software level, via a conventional network.

The advantages of shared-nothing are that it has the potential to scale linearly, it can use whatever hardware offers the best price/performance ratio (especially in the cloud), it can more easily adjust its hardware resources as load increases or decreases, and it can achieve greater fault tolerance by distributing the system across multiple data centers and regions. The downsides are that it requires explicit data partitioning (see [Link to Come]), and it incurs all the complexity of distributed systems ([Link to Come]).

Some cloud-native database systems use separate services for storage and transaction execution (see [“Separation of storage and compute”](ch01.html#sec_introduction_storage_compute)), with multiple compute nodes sharing access to the same storage service. This model has some similarity to a shared-disk architecture, but it avoids the scalability problems of older systems: instead of providing a filesystem (NAS) or block device (SAN) abstraction, the storage service offers a specialized API that is designed for the specific needs of the database [[75](ch02.html#Antonopoulos2019_ch2)].



### 可伸縮性原則

在大規模執行的系統架構通常高度特定於應用——沒有所謂的通用、一刀切的可擴充套件架構（非正式稱為*魔法擴充套件醬*）。例如，一個設計為每秒處理100,000個請求，每個請求1 kB大小的系統，與一個設計為每分鐘處理3個請求，每個請求2 GB大小的系統看起來完全不同——儘管這兩個系統有相同的資料吞吐量（100 MB/秒）。

此外，適用於某一負載水平的架構不太可能應對10倍的負載。因此，如果您正在處理一個快速增長的服務，很可能您需要在每個數量級負載增加時重新思考您的架構。由於應用的需求可能會發展變化，通常不值得提前超過一個數量級來規劃未來的擴充套件需求。

一個關於可擴充套件性的好的一般原則是將系統分解成可以相對獨立執行的小元件。這是微服務背後的基本原則（見[“微服務與無伺服器”](ch01.html#sec_introduction_microservices)）、分割槽（[連結即將到來]）、流處理（[連結即將到來]）和無共享架構。然而，挑戰在於知道在應該在一起的事物和應該分開的事物之間劃線的位置。關於微服務的設計指南可以在其他書籍中找到[[76](ch02.html#Newman2021_ch2)]，我們將在[連結即將到來]中討論無共享系統的分割槽。

另一個好的原則是不要讓事情變得比必要的更複雜。如果單機資料庫可以完成工作，它可能比複雜的分散式設定更可取。自動擴充套件系統（根據需求自動增加或減少資源）很酷，但如果您的負載相當可預測，手動擴充套件的系統可能會有更少的運營驚喜（見[連結即將到來]）。一個擁有五個服務的系統比擁有五十個服務的系統簡單。好的架構通常涉及到方法的實用混合。


The architecture of systems that operate at large scale is usually highly specific to the application—there is no such thing as a generic, one-size-fits-all scalable architecture (informally known as *magic scaling sauce*). For example, a system that is designed to handle 100,000 requests per second, each 1 kB in size, looks very different from a system that is designed for 3 requests per minute, each 2 GB in size—even though the two systems have the same data throughput (100 MB/sec).

Moreover, an architecture that is appropriate for one level of load is unlikely to cope with 10 times that load. If you are working on a fast-growing service, it is therefore likely that you will need to rethink your architecture on every order of magnitude load increase. As the needs of the application are likely to evolve, it is usually not worth planning future scaling needs more than one order of magnitude in advance.

A good general principle for scalability is to break a system down into smaller components that can operate largely independently from each other. This is the underlying principle behind microservices (see [“Microservices and Serverless”](ch01.html#sec_introduction_microservices)), partitioning ([Link to Come]), stream processing ([Link to Come]), and shared-nothing architectures. However, the challenge is in knowing where to draw the line between things that should be together, and things that should be apart. Design guidelines for microservices can be found in other books [[76](ch02.html#Newman2021_ch2)], and we discuss partitioning of shared-nothing systems in [Link to Come].

Another good principle is not to make things more complicated than necessary. If a single-machine database will do the job, it’s probably preferable to a complicated distributed setup. Auto-scaling systems (which automatically add or remove resources in response to demand) are cool, but if your load is fairly predictable, a manually scaled system may have fewer operational surprises (see [Link to Come]). A system with five services is simpler than one with fifty. Good architectures usually involve a pragmatic mixture of approaches.






--------

## 可維護性

軟體不會磨損或遭受材料疲勞，因此它的損壞方式與機械物體不同。但應用程式的需求經常變化，軟體執行的環境也在變化（如其依賴關係和底層平臺），並且它有需要修復的錯誤。

廣泛認為，軟體的大部分成本不在於初始開發，而在於持續的維護——修復錯誤、保持系統執行、調查故障、適應新平臺、針對新用例修改軟體、償還技術債務以及新增新功能[77，78]。

然而，維護也很困難。如果一個系統已經成功執行很長時間，它可能會使用一些今天很少有工程師理解的過時技術（如大型機和COBOL程式碼）；隨著人員離職，關於系統如何以及為什麼以某種方式設計的機構知識可能已經丟失；可能需要修復其他人的錯誤。此外，計算機系統往往與它支援的人類組織交織在一起，這意味著維護這種遺留系統既是一個人的問題也是一個技術問題[79]。

如果一個系統足夠有價值，能長時間存活，我們今天建立的每個系統終將成為遺留系統。為了最小化未來維護我們軟體的後代所承受的痛苦，我們應當在設計時考慮維護問題。雖然我們無法總是預測哪些決策將在未來造成維護難題，但在本書中，我們將關注幾個廣泛適用的原則：

Software does not wear out or suffer material fatigue, so it does not break in the same ways as mechanical objects do. But the requirements for an application frequently change, the environment that the software runs in changes (such as its dependencies and the underlying platform), and it has bugs that need fixing.

It is widely recognized that the majority of the cost of software is not in its initial development, but in its ongoing maintenance—fixing bugs, keeping its systems operational, investigating failures, adapting it to new platforms, modifying it for new use cases, repaying technical debt, and adding new features [[77](ch02.html#Ensmenger2016), [78](ch02.html#Glass2002)].

However, maintenance is also difficult. If a system has been successfully running for a long time, it may well use outdated technologies that not many engineers understand today (such as mainframes and COBOL code); institutional knowledge of how and why a system was designed in a certain way may have been lost as people have left the organization; it might be necessary to fix other people’s mistakes. Moreover, the computer system is often intertwined with the human organization that it supports, which means that maintenance of such *legacy* systems is as much a people problem as a technical one [[79](ch02.html#Bellotti2021)].

Every system we create today will one day become a legacy system if it is valuable enough to survive for a long time. In order to minimize the pain for future generations who need to maintain our software, we should design it with maintenance concerns in mind. Although we cannot always predict which decisions might create maintenance headaches in the future, in this book we will pay attention to several principles that are widely applicable:

* 可操作性（Operability）

  便於運維團隊保持系統平穩執行。

* 簡單性（Simplicity）

  讓新工程師也能輕鬆理解系統 —— 透過使用眾所周知、協調一致的模式和結構來實現系統，並避免不必要的**複雜性（Complexity）**。

* 可演化性（Evolvability）

  使工程師能夠輕鬆地對系統進行改造，並在未來出現需求變化時，能使其適應和擴充套件到新的應用場景中。



### 可操作性：人生苦短，關愛運維

我們先前在[雲時代的運營](ch1.md#在雲時代的運營)中討論過運維的角色，不難發現在這個過程中人類扮演的角色至少也是與工具一樣重要的。 實際上有人認為，“良好的運維經常可以繞開垃圾（或不完整）軟體的侷限性，而再好的軟體攤上垃圾運維也沒法可靠執行”。儘管運維的某些方面可以，而且應該是自動化的，但在最初建立正確運作的自動化機制仍然取決於人。

運維團隊對於保持軟體系統順利執行至關重要。一個優秀運維團隊的典型職責如下（或者更多）【29】：

* 監控系統的執行狀況，並在服務狀態不佳時快速恢復服務。
* 跟蹤問題的原因，例如系統故障或效能下降。
* 及時更新軟體和平臺，比如安全補丁。
* 瞭解系統間的相互作用，以便在異常變更造成損失前進行規避。
* 預測未來的問題，並在問題出現之前加以解決（例如，容量規劃）。
* 建立部署、配置、管理方面的良好實踐，編寫相應工具。
* 執行複雜的維護任務，例如將應用程式從一個平臺遷移到另一個平臺。
* 當配置變更時，維持系統的安全性。
* 定義工作流程，使運維操作可預測，並保持生產環境穩定。
* 鐵打的營盤流水的兵，維持組織對系統的瞭解。

良好的可操作性意味著更輕鬆的日常工作，進而運維團隊能專注於高價值的事情。資料系統可以透過各種方式使日常任務更輕鬆：

* 透過良好的監控，提供對系統內部狀態和執行時行為的 **可見性（visibility）**。
* 為自動化提供良好支援，將系統與標準化工具相整合。
* 避免依賴單臺機器（在整個系統繼續不間斷執行的情況下允許機器停機維護）。
* 提供良好的文件和易於理解的操作模型（“如果做 X，會發生 Y”）。
* 提供良好的預設行為，但需要時也允許管理員自由覆蓋預設值。
* 有條件時進行自我修復，但需要時也允許管理員手動控制系統狀態。
* 行為可預測，最大限度減少意外。

We previously discussed the role of operations in [“Operations in the Cloud Era”](ch01.html#sec_introduction_operations), and we saw that human processes are at least as important for reliable operations as software tools. In fact, it has been suggested that “good operations can often work around the limitations of bad (or incomplete) software, but good software cannot run reliably with bad operations” [[54](ch02.html#Kreps2012_ch1)].

In large-scale systems consisting of many thousands of machines, manual maintenance would be unreasonably expensive, and automation is essential. However, automation can be a two-edged sword: there will always be edge cases (such as rare failure scenarios) that require manual intervention from the operations team. Since the cases that cannot be handled automatically are the most complex issues, greater automation requires a *more* skilled operations team that can resolve those issues [[80](ch02.html#Bainbridge1983)].

Moreover, if an automated system goes wrong, it is often harder to troubleshoot than a system that relies on an operator to perform some actions manually. For that reason, it is not the case that more automation is always better for operability. However, some amount of automation is important, and the sweet spot will depend on the specifics of your particular application and organization.

Good operability means making routine tasks easy, allowing the operations team to focus their efforts on high-value activities. Data systems can do various things to make routine tasks easy, including [[81](ch02.html#Hamilton2007)]:

- Allowing monitoring tools to check the system’s key metrics, and supporting observability tools (see [“Problems with Distributed Systems”](ch01.html#sec_introduction_dist_sys_problems)) to give insights into the system’s runtime behavior. A variety of commercial and open source tools can help here [[82](ch02.html#Horovits2021)].
- Avoiding dependency on individual machines (allowing machines to be taken down for maintenance while the system as a whole continues running uninterrupted)
- Providing good documentation and an easy-to-understand operational model (“If I do X, Y will happen”)
- Providing good default behavior, but also giving administrators the freedom to override defaults when needed
- Self-healing where appropriate, but also giving administrators manual control over the system state when needed
- Exhibiting predictable behavior, minimizing surprises





### 簡單性：管理複雜度

小型軟體專案可以使用簡單討喜的、富表現力的程式碼，但隨著專案越來越大，程式碼往往變得非常複雜，難以理解。這種複雜度拖慢了所有系統相關人員，進一步增加了維護成本。一個陷入複雜泥潭的軟體專案有時被描述為 **爛泥潭（a big ball of mud）** 【30】。

**複雜度（complexity）** 有各種可能的症狀，例如：狀態空間激增、模組間緊密耦合、糾結的依賴關係、不一致的命名和術語、解決效能問題的 Hack、需要繞開的特例等等，現在已經有很多關於這個話題的討論【31,32,33】。

因為複雜度導致維護困難時，預算和時間安排通常會超支。在複雜的軟體中進行變更，引入錯誤的風險也更大：當開發人員難以理解系統時，隱藏的假設、無意的後果和意外的互動就更容易被忽略。相反，降低複雜度能極大地提高軟體的可維護性，因此簡單性應該是構建系統的一個關鍵目標。

簡化系統並不一定意味著減少功能；它也可以意味著消除 **額外的（accidental）** 的複雜度。Moseley 和 Marks【32】把 **額外複雜度** 定義為：由具體實現中湧現，而非（從使用者視角看，系統所解決的）問題本身固有的複雜度。

用於消除 **額外複雜度** 的最好工具之一是 **抽象（abstraction）**。一個好的抽象可以將大量實現細節隱藏在一個乾淨，簡單易懂的外觀下面。一個好的抽象也可以廣泛用於各類不同應用。比起重複造很多輪子，重用抽象不僅更有效率，而且有助於開發高質量的軟體。抽象元件的質量改進將使所有使用它的應用受益。

例如，高階程式語言是一種抽象，隱藏了機器碼、CPU 暫存器和系統呼叫。SQL 也是一種抽象，隱藏了複雜的磁碟 / 記憶體資料結構、來自其他客戶端的併發請求、崩潰後的不一致性。當然在用高階語言程式設計時，我們仍然用到了機器碼；只不過沒有 **直接（directly）** 使用罷了，正是因為程式語言的抽象，我們才不必去考慮這些實現細節。

抽象可以幫助我們將系統的複雜度控制在可管理的水平，不過，找到好的抽象是非常困難的。在分散式系統領域雖然有許多好的演算法，但我們並不清楚它們應該打包成什麼樣抽象。

本書將緊盯那些允許我們將大型系統的部分提取為定義明確的、可重用的元件的優秀抽象。

Small software projects can have delightfully simple and expressive code, but as projects get larger, they often become very complex and difficult to understand. This complexity slows down everyone who needs to work on the system, further increasing the cost of maintenance. A software project mired in complexity is sometimes described as a *big ball of mud* [[83](ch02.html#Foote1997)].

When complexity makes maintenance hard, budgets and schedules are often overrun. In complex software, there is also a greater risk of introducing bugs when making a change: when the system is harder for developers to understand and reason about, hidden assumptions, unintended consequences, and unexpected interactions are more easily overlooked [[62](ch02.html#Woods2017)]. Conversely, reducing complexity greatly improves the maintainability of software, and thus simplicity should be a key goal for the systems we build.

Simple systems are easier to understand, and therefore we should try to solve a given problem in the simplest way possible. Unfortunately, this is easier said than done. Whether something is simple or not is often a subjective matter of taste, as there is no objective standard of simplicity [[84](ch02.html#Brooker2022)]. For example, one system may hide a complex implementation behind a simple interface, whereas another may have a simple implementation that exposes more internal detail to its users—which one is simpler?

One attempt at reasoning about complexity has been to break it down into two categories, *essential* and *accidental* complexity [[85](ch02.html#Brooks1995)]. The idea is that essential complexity is inherent in the problem domain of the application, while accidental complexity arises only because of limitations of our tooling. Unfortunately, this distinction is also flawed, because boundaries between the essential and the accidental shift as our tooling evolves [[86](ch02.html#Luu2020)].

One of the best tools we have for managing complexity is *abstraction*. A good abstraction can hide a great deal of implementation detail behind a clean, simple-to-understand façade. A good abstraction can also be used for a wide range of different applications. Not only is this reuse more efficient than reimplementing a similar thing multiple times, but it also leads to higher-quality software, as quality improvements in the abstracted component benefit all applications that use it.

For example, high-level programming languages are abstractions that hide machine code, CPU registers, and syscalls. SQL is an abstraction that hides complex on-disk and in-memory data structures, concurrent requests from other clients, and inconsistencies after crashes. Of course, when programming in a high-level language, we are still using machine code; we are just not using it *directly*, because the programming language abstraction saves us from having to think about it.

Abstractions for application code, which aim to reduce its complexity, can be created using methodologies such as *design patterns* [[87](ch02.html#Gamma1994)] and *domain-driven design* (DDD) [[88](ch02.html#Evans2003)]. This book is not about such application-specific abstractions, but rather about general-purpose abstractions on top of which you can build your applications, such as database transactions, indexes, and event logs. If you want to use techniques such as DDD, you can implement them on top of the foundations described in this book.

### 可演化性：讓變更更容易

系統的需求永遠不變，基本是不可能的。更可能的情況是，它們處於常態的變化中，例如：你瞭解了新的事實、出現意想不到的應用場景、業務優先順序發生變化、使用者要求新功能、新平臺取代舊平臺、法律或監管要求發生變化、系統增長迫使架構變化等。

在組織流程方面，**敏捷（agile）** 工作模式為適應變化提供了一個框架。敏捷社群還開發了對在頻繁變化的環境中開發軟體很有幫助的技術工具和模式，如 **測試驅動開發（TDD, test-driven development）** 和 **重構（refactoring）** 。

這些敏捷技術的大部分討論都集中在相當小的規模（同一個應用中的幾個程式碼檔案）。本書將探索在更大資料系統層面上提高敏捷性的方法，可能由幾個不同的應用或服務組成。例如，為了將裝配主頁時間線的方法從方法 1 變為方法 2，你會如何 “重構” 推特的架構 ？

修改資料系統並使其適應不斷變化需求的容易程度，是與 **簡單性** 和 **抽象性** 密切相關的：簡單易懂的系統通常比複雜系統更容易修改。但由於這是一個非常重要的概念，我們將用一個不同的詞來指代資料系統層面的敏捷性： **可演化性（evolvability）** 【34】。


It’s extremely unlikely that your system’s requirements will remain unchanged forever. They are much more likely to be in constant flux: you learn new facts, previously unanticipated use cases emerge, business priorities change, users request new features, new platforms replace old platforms, legal or regulatory requirements change, growth of the system forces architectural changes, etc.

In terms of organizational processes, *Agile* working patterns provide a framework for adapting to change. The Agile community has also developed technical tools and processes that are helpful when developing software in a frequently changing environment, such as test-driven development (TDD) and refactoring. In this book, we search for ways of increasing agility at the level of a system consisting of several different applications or services with different characteristics.

The ease with which you can modify a data system, and adapt it to changing requirements, is closely linked to its simplicity and its abstractions: simple and easy-to-understand systems are usually easier to modify than complex ones. Since this is such an important idea, we will use a different word to refer to agility on a data system level: *evolvability* [[89](ch02.html#Breivold2008)].

One major factor that makes change difficult in large systems is when some action is irreversible, and therefore that action needs to be taken very carefully [[90](ch02.html#Zaninotto2002)]. For example, say you are migrating from one database to another: if you cannot switch back to the old system in case of problems wth the new one, the stakes are much higher than if you can easily go back. Minimizing irreversibility improves flexibility.





--------

## 本章小結

在本章中，我們檢查了幾個非功能性需求的示例：效能、可靠性、可擴充套件性和可維護性。透過這些話題，我們還遇到了我們在本書其餘部分將需要的原則和術語。我們從一個案例研究開始，探討了如何在社交網路中實現首頁時間線，這展示了在規模擴大時可能出現的一些挑戰。

我們討論了如何測量效能（例如，使用響應時間百分位數）、系統負載（例如，使用吞吐量指標），以及它們如何在SLA中使用。可擴充套件性是一個密切相關的概念：即確保在負載增長時效能保持不變。我們看到了一些可擴充套件性的一般原則，如將任務分解成可以獨立操作的小部分，並將在後續章節中深入技術細節探討可擴充套件性技術。

為了實現可靠性，您可以使用容錯技術，即使系統的某個元件（例如，磁碟、機器或其他服務）出現故障，也能繼續提供服務。我們看到了可能發生的硬體故障示例，並將其與軟體故障區分開來，後者可能更難處理，因為它們往往具有強相關性。實現可靠性的另一個方面是構建對人為錯誤的抵抗力，我們看到了無責任事故報告作為從事件中學習的一種技術。

最後，我們檢查了幾個維護性的方面，包括支援運營團隊的工作、管理複雜性，以及使應用功能隨時間易於演進。關於如何實現這些目標沒有簡單的答案，但有一件事可以幫助，那就是使用提供有用抽象的、眾所周知的構建塊來構建應用程式。本書的其餘部分將介紹一些最重要的這類構建塊。

In this chapter we examined several examples of nonfunctional requirements: performance, reliability, scalability, and maintainability. Through these topics we have also encountered principles and terminology that we will need throughout the rest of the book. We started with a case study of how one might implement home timelines in a social network, which illustrated some of the challenges that arise at scale.

We discussed how to measure performance (e.g., using response time percentiles), the load on a system (e.g., using throughput metrics), and how they are used in SLAs. Scalability is a closely related concept: that is, ensuring performance stays the same when the load grows. We saw some general principles for scalability, such as breaking a task down into smaller parts that can operate independently, and we will dive into deep technical detail on scalability techniques in the following chapters.

To achieve reliability, you can use fault tolerance techniques, which allow a system to continue providing its service even if some component (e.g., a disk, a machine, or another service) is faulty. We saw examples of hardware faults that can occur, and distinguished them from software faults, which can be harder to deal with because they are often strongly correlated. Another aspect of achieving reliability is to build resilience against humans making mistakes, and we saw blameless postmortems as a technique for learning from incidents.

Finally, we examined several facets of maintainability, including supporting the work of operations teams, managing complexity, and making it easy to evolve an application’s functionality over time. There are no easy answers on how to achieve these things, but one thing that can help is to build applications using well-understood building blocks that provide useful abstractions. The rest of this book will cover a selection of the most important such building blocks.



--------

## 參考文獻

[[1](ch02.html#Cvet2016-marker)] Mike Cvet. [How We Learned to Stop Worrying and Love Fan-In at Twitter](https://www.youtube.com/watch?v=WEgCjwyXvwc). At *QCon San Francisco*, December 2016.

[[2](ch02.html#Krikorian2012_ch2-marker)] Raffi Krikorian. [Timelines at Scale](http://www.infoq.com/presentations/Twitter-Timeline-Scalability). At *QCon San Francisco*, November 2012. Archived at [perma.cc/V9G5-KLYK](https://perma.cc/V9G5-KLYK)

[[3](ch02.html#Twitter2023-marker)] Twitter. [Twitter’s Recommendation Algorithm](https://blog.twitter.com/engineering/en_us/topics/open-source/2023/twitter-recommendation-algorithm). *blog.twitter.com*, March 2023. Archived at [perma.cc/L5GT-229T](https://perma.cc/L5GT-229T)

[[4](ch02.html#Krikorian2013-marker)] Raffi Krikorian. [New Tweets per second record, and how!](https://blog.twitter.com/engineering/en_us/a/2013/new-tweets-per-second-record-and-how) *blog.twitter.com*, August 2013. Archived at [perma.cc/6JZN-XJYN](https://perma.cc/6JZN-XJYN)

[[5](ch02.html#Axon2010_ch2-marker)] Samuel Axon. [3% of Twitter’s Servers Dedicated to Justin Bieber](http://mashable.com/2010/09/07/justin-bieber-twitter/). *mashable.com*, September 2010. Archived at [perma.cc/F35N-CGVX](https://perma.cc/F35N-CGVX)

[[6](ch02.html#Bronson2021-marker)] Nathan Bronson, Abutalib Aghayev, Aleksey Charapko, and Timothy Zhu. [Metastable Failures in Distributed Systems](https://sigops.org/s/conferences/hotos/2021/papers/hotos21-s11-bronson.pdf). At *Workshop on Hot Topics in Operating Systems* (HotOS), May 2021. [doi:10.1145/3458336.3465286](https://doi.org/10.1145/3458336.3465286)

[[7](ch02.html#Brooker2021-marker)] Marc Brooker. [Metastability and Distributed Systems](https://brooker.co.za/blog/2021/05/24/metastable.html). *brooker.co.za*, May 2021. Archived at [archive.org](https://web.archive.org/web/20230324043015/https://brooker.co.za/blog/2021/05/24/metastable.html)

[[8](ch02.html#Brooker2015-marker)] Marc Brooker. [Exponential Backoff And Jitter](https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/). *aws.amazon.com*, March 2015. Archived at [perma.cc/R6MS-AZKH](https://perma.cc/R6MS-AZKH)

[[9](ch02.html#Brooker2022backoff-marker)] Marc Brooker. [What is Backoff For?](https://brooker.co.za/blog/2022/08/11/backoff.html) *brooker.co.za*, August 2022. Archived at [archive.org](https://web.archive.org/web/20230331022111/https://brooker.co.za/blog/2022/08/11/backoff.html)

[[10](ch02.html#Nygard2018-marker)] Michael T. Nygard. [*Release It!*](https://learning.oreilly.com/library/view/release-it-2nd/9781680504552/), 2nd Edition. Pragmatic Bookshelf, January 2018. ISBN: 9781680502398

[[11](ch02.html#Brooker2022retries-marker)] Marc Brooker. [Fixing retries with token buckets and circuit breakers](https://brooker.co.za/blog/2022/02/28/retries.html). *brooker.co.za*, February 2022. Archived at [archive.org](https://web.archive.org/web/20230325195445/https://brooker.co.za/blog/2022/02/28/retries.html)

[[12](ch02.html#YanacekLoadShedding-marker)] David Yanacek. [Using load shedding to avoid overload](https://aws.amazon.com/builders-library/using-load-shedding-to-avoid-overload/). Amazon Builders’ Library, *aws.amazon.com*. Archived at [perma.cc/9SAW-68MP](https://perma.cc/9SAW-68MP)

[[13](ch02.html#Sackman2016_ch2-marker)] Matthew Sackman. [Pushing Back](https://wellquite.org/posts/lshift/pushing_back/). *wellquite.org*, May 2016. Archived at [perma.cc/3KCZ-RUFY](https://perma.cc/3KCZ-RUFY)

[[14](ch02.html#Kopytkov2018-marker)] Dmitry Kopytkov and Patrick Lee. [Meet Bandaid, the Dropbox service proxy](https://dropbox.tech/infrastructure/meet-bandaid-the-dropbox-service-proxy). *dropbox.tech*, March 2018. Archived at [perma.cc/KUU6-YG4S](https://perma.cc/KUU6-YG4S)

[[15](ch02.html#Gunawi2018-marker)] Haryadi S. Gunawi, Riza O. Suminto, Russell Sears, Casey Golliher, Swaminathan Sundararaman, Xing Lin, Tim Emami, Weiguang Sheng, Nematollah Bidokhti, Caitie McCaffrey, Gary Grider, Parks M. Fields, Kevin Harms, Robert B. Ross, Andree Jacobson, Robert Ricci, Kirk Webb, Peter Alvaro, H. Birali Runesha, Mingzhe Hao, and Huaicheng Li. [Fail-Slow at Scale: Evidence of Hardware Performance Faults in Large Production Systems](https://www.usenix.org/system/files/conference/fast18/fast18-gunawi.pdf). At *16th USENIX Conference on File and Storage Technologies*, February 2018.

[[16](ch02.html#DeCandia2007_ch1-marker)] Giuseppe DeCandia, Deniz Hastorun, Madan Jampani, Gunavardhan Kakulapati, Avinash Lakshman, Alex Pilchin, Swaminathan Sivasubramanian, Peter Vosshall, and Werner Vogels. [Dynamo: Amazon’s Highly Available Key-Value Store](http://www.allthingsdistributed.com/files/amazon-dynamo-sosp2007.pdf). At *21st ACM Symposium on Operating Systems Principles* (SOSP), October 2007. [doi:10.1145/1294261.1294281](https://doi.org/10.1145/1294261.1294281)

[[17](ch02.html#Whitenton2020-marker)] Kathryn Whitenton. [The Need for Speed, 23 Years Later](https://www.nngroup.com/articles/the-need-for-speed/). *nngroup.com*, May 2020. Archived at [perma.cc/C4ER-LZYA](https://perma.cc/C4ER-LZYA)

[[18](ch02.html#Linden2006-marker)] Greg Linden. [Marissa Mayer at Web 2.0](https://glinden.blogspot.com/2006/11/marissa-mayer-at-web-20.html). *glinden.blogspot.com*, November 2005. Archived at [perma.cc/V7EA-3VXB](https://perma.cc/V7EA-3VXB)

[[19](ch02.html#Brutlag2009-marker)] Jake Brutlag. [Speed Matters for Google Web Search](https://services.google.com/fh/files/blogs/google_delayexp.pdf). *services.google.com*, June 2009. Archived at [perma.cc/BK7R-X7M2](https://perma.cc/BK7R-X7M2)

[[20](ch02.html#Schurman2009-marker)] Eric Schurman and Jake Brutlag. [Performance Related Changes and their User Impact](https://www.youtube.com/watch?v=bQSE51-gr2s). Talk at *Velocity 2009*.

[[21](ch02.html#Akamai2017-marker)] Akamai Technologies, Inc. [The State of Online Retail Performance](https://web.archive.org/web/20210729180749/https://www.akamai.com/us/en/multimedia/documents/report/akamai-state-of-online-retail-performance-spring-2017.pdf). *akamai.com*, April 2017. Archived at [perma.cc/UEK2-HYCS](https://perma.cc/UEK2-HYCS)

[[22](ch02.html#Bai2017-marker)] Xiao Bai, Ioannis Arapakis, B. Barla Cambazoglu, and Ana Freire. [Understanding and Leveraging the Impact of Response Latency on User Behaviour in Web Search](https://iarapakis.github.io/papers/TOIS17.pdf). *ACM Transactions on Information Systems*, volume 36, issue 2, article 21, April 2018. [doi:10.1145/3106372](https://doi.org/10.1145/3106372)

[[23](ch02.html#Dean2013-marker)] Jeffrey Dean and Luiz André Barroso. [The Tail at Scale](http://cacm.acm.org/magazines/2013/2/160173-the-tail-at-scale/fulltext). *Communications of the ACM*, volume 56, issue 2, pages 74–80, February 2013. [doi:10.1145/2408776.2408794](https://doi.org/10.1145/2408776.2408794)

[[24](ch02.html#Hidalgo2020-marker)] Alex Hidalgo. [*Implementing Service Level Objectives: A Practical Guide to SLIs, SLOs, and Error Budgets*](https://www.oreilly.com/library/view/implementing-service-level/9781492076803/). O’Reilly Media, September 2020. ISBN: 1492076813

[[25](ch02.html#Mogul2019-marker)] Jeffrey C. Mogul and John Wilkes. [Nines are Not Enough: Meaningful Metrics for Clouds](https://research.google/pubs/pub48033/). At *17th Workshop on Hot Topics in Operating Systems* (HotOS), May 2019. [doi:10.1145/3317550.3321432](https://doi.org/10.1145/3317550.3321432)

[[26](ch02.html#Hauer2020-marker)] Tamás Hauer, Philipp Hoffmann, John Lunney, Dan Ardelean, and Amer Diwan. [Meaningful Availability](https://www.usenix.org/conference/nsdi20/presentation/hauer). At *17th USENIX Symposium on Networked Systems Design and Implementation* (NSDI), February 2020.

[[27](ch02.html#Dunning2021-marker)] Ted Dunning. [The t-digest: Efficient estimates of distributions](https://www.sciencedirect.com/science/article/pii/S2665963820300403). *Software Impacts*, volume 7, article 100049, February 2021. [doi:10.1016/j.simpa.2020.100049](https://doi.org/10.1016/j.simpa.2020.100049)

[[28](ch02.html#Kohn2021-marker)] David Kohn. [How percentile approximation works (and why it’s more useful than averages)](https://www.timescale.com/blog/how-percentile-approximation-works-and-why-its-more-useful-than-averages/). *timescale.com*, September 2021. Archived at [perma.cc/3PDP-NR8B](https://perma.cc/3PDP-NR8B)

[[29](ch02.html#Hartmann2020-marker)] Heinrich Hartmann and Theo Schlossnagle. [Circllhist — A Log-Linear Histogram Data Structure for IT Infrastructure Monitoring](https://arxiv.org/pdf/2001.06561.pdf). *arxiv.org*, January 2020.

[[30](ch02.html#Masson2019-marker)] Charles Masson, Jee E. Rim, and Homin K. Lee. [DDSketch: A Fast and Fully-Mergeable Quantile Sketch with Relative-Error Guarantees](http://www.vldb.org/pvldb/vol12/p2195-masson.pdf). *Proceedings of the VLDB Endowment*, volume 12, issue 12, pages 2195–2205, August 2019. [doi:10.14778/3352063.3352135](https://doi.org/10.14778/3352063.3352135)

[[31](ch02.html#Schwartz2015-marker)] Baron Schwartz. [Why Percentiles Don’t Work the Way You Think](https://orangematter.solarwinds.com/2016/11/18/why-percentiles-dont-work-the-way-you-think/). *solarwinds.com*, November 2016. Archived at [perma.cc/469T-6UGB](https://perma.cc/469T-6UGB)

[[32](ch02.html#Heimerdinger1992-marker)] Walter L. Heimerdinger and Charles B. Weinstock. [A Conceptual Framework for System Fault Tolerance](https://resources.sei.cmu.edu/asset_files/TechnicalReport/1992_005_001_16112.pdf). Technical Report CMU/SEI-92-TR-033, Software Engineering Institute, Carnegie Mellon University, October 1992. Archived at [perma.cc/GD2V-DMJW](https://perma.cc/GD2V-DMJW)

[[33](ch02.html#Gaertner1999-marker)] Felix C. Gärtner. [Fundamentals of fault-tolerant distributed computing in asynchronous environments](https://dl.acm.org/doi/pdf/10.1145/311531.311532). *ACM Computing Surveys*, volume 31, issue 1, pages 1–26, March 1999. [doi:10.1145/311531.311532](https://doi.org/10.1145/311531.311532)

[[34](ch02.html#Yuan2014-marker)] Ding Yuan, Yu Luo, Xin Zhuang, Guilherme Renna Rodrigues, Xu Zhao, Yongle Zhang, Pranay U. Jain, and Michael Stumm. [Simple Testing Can Prevent Most Critical Failures: An Analysis of Production Failures in Distributed Data-Intensive Systems](https://www.usenix.org/system/files/conference/osdi14/osdi14-paper-yuan.pdf). At *11th USENIX Symposium on Operating Systems Design and Implementation* (OSDI), October 2014.

[[35](ch02.html#Rosenthal2020-marker)] Casey Rosenthal and Nora Jones. [*Chaos Engineering*](https://learning.oreilly.com/library/view/chaos-engineering/9781492043850/). O’Reilly Media, April 2020. ISBN: 9781492043867

[[36](ch02.html#Pinheiro2007-marker)] Eduardo Pinheiro, Wolf-Dietrich Weber, and Luiz Andre Barroso. [Failure Trends in a Large Disk Drive Population](https://www.usenix.org/legacy/events/fast07/tech/full_papers/pinheiro/pinheiro_old.pdf). At *5th USENIX Conference on File and Storage Technologies* (FAST), February 2007.

[[37](ch02.html#Schroeder2007-marker)] Bianca Schroeder and Garth A. Gibson. [Disk failures in the real world: What does an MTTF of 1,000,000 hours mean to you?](https://www.usenix.org/legacy/events/fast07/tech/schroeder/schroeder.pdf) At *5th USENIX Conference on File and Storage Technologies* (FAST), February 2007.

[[38](ch02.html#Klein2021-marker)] Andy Klein. [Backblaze Drive Stats for Q2 2021](https://www.backblaze.com/blog/backblaze-drive-stats-for-q2-2021/). *backblaze.com*, August 2021. Archived at [perma.cc/2943-UD5E](https://perma.cc/2943-UD5E)

[[39](ch02.html#Narayanan2016-marker)] Iyswarya Narayanan, Di Wang, Myeongjae Jeon, Bikash Sharma, Laura Caulfield, Anand Sivasubramaniam, Ben Cutler, Jie Liu, Badriddine Khessib, and Kushagra Vaid. [SSD Failures in Datacenters: What? When? and Why?](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/08/a7-narayanan.pdf) At *9th ACM International on Systems and Storage Conference* (SYSTOR), June 2016. [doi:10.1145/2928275.2928278](https://doi.org/10.1145/2928275.2928278)

[[40](ch02.html#Alibaba2019_ch2-marker)] Alibaba Cloud Storage Team. [Storage System Design Analysis: Factors Affecting NVMe SSD Performance (1)](https://www.alibabacloud.com/blog/594375). *alibabacloud.com*, January 2019. Archived at [archive.org](https://web.archive.org/web/20230522005034/https://www.alibabacloud.com/blog/594375)

[[41](ch02.html#Schroeder2016-marker)] Bianca Schroeder, Raghav Lagisetty, and Arif Merchant. [Flash Reliability in Production: The Expected and the Unexpected](https://www.usenix.org/system/files/conference/fast16/fast16-papers-schroeder.pdf). At *14th USENIX Conference on File and Storage Technologies* (FAST), February 2016.

[[42](ch02.html#Alter2019-marker)] Jacob Alter, Ji Xue, Alma Dimnaku, and Evgenia Smirni. [SSD failures in the field: symptoms, causes, and prediction models](https://dl.acm.org/doi/pdf/10.1145/3295500.3356172). At *International Conference for High Performance Computing, Networking, Storage and Analysis* (SC), November 2019. [doi:10.1145/3295500.3356172](https://doi.org/10.1145/3295500.3356172)

[[43](ch02.html#Ford2010-marker)] Daniel Ford, François Labelle, Florentina I. Popovici, Murray Stokely, Van-Anh Truong, Luiz Barroso, Carrie Grimes, and Sean Quinlan. [Availability in Globally Distributed Storage Systems](https://www.usenix.org/legacy/event/osdi10/tech/full_papers/Ford.pdf). At *9th USENIX Symposium on Operating Systems Design and Implementation* (OSDI), October 2010.

[[44](ch02.html#Vishwanath2010-marker)] Kashi Venkatesh Vishwanath and Nachiappan Nagappan. [Characterizing Cloud Computing Hardware Reliability](https://www.microsoft.com/en-us/research/wp-content/uploads/2010/06/socc088-vishwanath.pdf). At *1st ACM Symposium on Cloud Computing* (SoCC), June 2010. [doi:10.1145/1807128.1807161](https://doi.org/10.1145/1807128.1807161)

[[45](ch02.html#Hochschild2021-marker)] Peter H. Hochschild, Paul Turner, Jeffrey C. Mogul, Rama Govindaraju, Parthasarathy Ranganathan, David E. Culler, and Amin Vahdat. [Cores that don’t count](https://sigops.org/s/conferences/hotos/2021/papers/hotos21-s01-hochschild.pdf). At *Workshop on Hot Topics in Operating Systems* (HotOS), June 2021. [doi:10.1145/3458336.3465297](https://doi.org/10.1145/3458336.3465297)

[[46](ch02.html#Dixit2021-marker)] Harish Dattatraya Dixit, Sneha Pendharkar, Matt Beadon, Chris Mason, Tejasvi Chakravarthy, Bharath Muthiah, and Sriram Sankar. [Silent Data Corruptions at Scale](https://arxiv.org/abs/2102.11245). *arXiv:2102.11245*, February 2021.

[[47](ch02.html#Behrens2015-marker)] Diogo Behrens, Marco Serafini, Sergei Arnautov, Flavio P. Junqueira, and Christof Fetzer. [Scalable Error Isolation for Distributed Systems](https://www.usenix.org/conference/nsdi15/technical-sessions/presentation/behrens). At *12th USENIX Symposium on Networked Systems Design and Implementation* (NSDI), May 2015.

[[48](ch02.html#Schroeder2009-marker)] Bianca Schroeder, Eduardo Pinheiro, and Wolf-Dietrich Weber. [DRAM Errors in the Wild: A Large-Scale Field Study](https://static.googleusercontent.com/media/research.google.com/en//pubs/archive/35162.pdf). At *11th International Joint Conference on Measurement and Modeling of Computer Systems* (SIGMETRICS), June 2009. [doi:10.1145/1555349.1555372](https://doi.org/10.1145/1555349.1555372)

[[49](ch02.html#Kim2014-marker)] Yoongu Kim, Ross Daly, Jeremie Kim, Chris Fallin, Ji Hye Lee, Donghyuk Lee, Chris Wilkerson, Konrad Lai, and Onur Mutlu. [Flipping Bits in Memory Without Accessing Them: An Experimental Study of DRAM Disturbance Errors](https://users.ece.cmu.edu/~yoonguk/papers/kim-isca14.pdf). At *41st Annual International Symposium on Computer Architecture* (ISCA), June 2014. [doi:10.5555/2665671.2665726](https://doi.org/10.5555/2665671.2665726)

[[50](ch02.html#Cockcroft2019-marker)] Adrian Cockcroft. [Failure Modes and Continuous Resilience](https://adrianco.medium.com/failure-modes-and-continuous-resilience-6553078caad5). *adrianco.medium.com*, November 2019. Archived at [perma.cc/7SYS-BVJP](https://perma.cc/7SYS-BVJP)

[[51](ch02.html#Han2021-marker)] Shujie Han, Patrick P. C. Lee, Fan Xu, Yi Liu, Cheng He, and Jiongzhou Liu. [An In-Depth Study of Correlated Failures in Production SSD-Based Data Centers](https://www.usenix.org/conference/fast21/presentation/han). At *19th USENIX Conference on File and Storage Technologies* (FAST), February 2021.

[[52](ch02.html#Nightingale2011-marker)] Edmund B. Nightingale, John R. Douceur, and Vince Orgovan. [Cycles, Cells and Platters: An Empirical Analysis of Hardware Failures on a Million Consumer PCs](https://eurosys2011.cs.uni-salzburg.at/pdf/eurosys2011-nightingale.pdf). At *6th European Conference on Computer Systems* (EuroSys), April 2011. [doi:10.1145/1966445.1966477](https://doi.org/10.1145/1966445.1966477)

[[53](ch02.html#Gunawi2014-marker)] Haryadi S. Gunawi, Mingzhe Hao, Tanakorn Leesatapornwongsa, Tiratat Patana-anake, Thanh Do, Jeffry Adityatama, Kurnia J. Eliazar, Agung Laksono, Jeffrey F. Lukman, Vincentius Martin, and Anang D. Satria. [What Bugs Live in the Cloud?](http://ucare.cs.uchicago.edu/pdf/socc14-cbs.pdf) At *5th ACM Symposium on Cloud Computing* (SoCC), November 2014. [doi:10.1145/2670979.2670986](https://doi.org/10.1145/2670979.2670986)

[[54](ch02.html#Kreps2012_ch1-marker)] Jay Kreps. [Getting Real About Distributed System Reliability](http://blog.empathybox.com/post/19574936361/getting-real-about-distributed-system-reliability). *blog.empathybox.com*, March 2012. Archived at [perma.cc/9B5Q-AEBW](https://perma.cc/9B5Q-AEBW)

[[55](ch02.html#Minar2012_ch1-marker)] Nelson Minar. [Leap Second Crashes Half the Internet](http://www.somebits.com/weblog/tech/bad/leap-second-2012.html). *somebits.com*, July 2012. Archived at [perma.cc/2WB8-D6EU](https://perma.cc/2WB8-D6EU)

[[56](ch02.html#HPE2019-marker)] Hewlett Packard Enterprise. [Support Alerts – Customer Bulletin a00092491en_us](https://support.hpe.com/hpesc/public/docDisplay?docId=emr_na-a00092491en_us). *support.hpe.com*, November 2019. Archived at [perma.cc/S5F6-7ZAC](https://perma.cc/S5F6-7ZAC)

[[57](ch02.html#Hochstein2020-marker)] Lorin Hochstein. [awesome limits](https://github.com/lorin/awesome-limits). *github.com*, November 2020. Archived at [perma.cc/3R5M-E5Q4](https://perma.cc/3R5M-E5Q4)

[[58](ch02.html#Tang2023-marker)] Lilia Tang, Chaitanya Bhandari, Yongle Zhang, Anna Karanika, Shuyang Ji, Indranil Gupta, and Tianyin Xu. [Fail through the Cracks: Cross-System Interaction Failures in Modern Cloud Systems](https://tianyin.github.io/pub/csi-failures.pdf). At *18th European Conference on Computer Systems* (EuroSys), May 2023. [doi:10.1145/3552326.3587448](https://doi.org/10.1145/3552326.3587448)

[[59](ch02.html#Ulrich2016-marker)] Mike Ulrich. [Addressing Cascading Failures](https://sre.google/sre-book/addressing-cascading-failures/). In Betsy Beyer, Jennifer Petoff, Chris Jones, and Niall Richard Murphy (ed). [*Site Reliability Engineering: How Google Runs Production Systems*](https://www.oreilly.com/library/view/site-reliability-engineering/9781491929117/). O’Reilly Media, 2016. ISBN: 9781491929124

[[60](ch02.html#Fassbender2022-marker)] Harri Faßbender. [Cascading failures in large-scale distributed systems](https://blog.mi.hdm-stuttgart.de/index.php/2022/03/03/cascading-failures-in-large-scale-distributed-systems/). *blog.mi.hdm-stuttgart.de*, March 2022. Archived at [perma.cc/K7VY-YJRX](https://perma.cc/K7VY-YJRX)

[[61](ch02.html#Cook2000-marker)] Richard I. Cook. [How Complex Systems Fail](https://www.adaptivecapacitylabs.com/HowComplexSystemsFail.pdf). Cognitive Technologies Laboratory, April 2000. Archived at [perma.cc/RDS6-2YVA](https://perma.cc/RDS6-2YVA)

[[62](ch02.html#Woods2017-marker)] David D Woods. [STELLA: Report from the SNAFUcatchers Workshop on Coping With Complexity](https://snafucatchers.github.io/). *snafucatchers.github.io*, March 2017. Archived at [archive.org](https://web.archive.org/web/20230306130131/https://snafucatchers.github.io/)

[[63](ch02.html#Oppenheimer2003-marker)] David Oppenheimer, Archana Ganapathi, and David A. Patterson. [Why Do Internet Services Fail, and What Can Be Done About It?](http://static.usenix.org/legacy/events/usits03/tech/full_papers/oppenheimer/oppenheimer.pdf) At *4th USENIX Symposium on Internet Technologies and Systems* (USITS), March 2003.

[[64](ch02.html#Dekker2017-marker)] Sidney Dekker. [*The Field Guide to Understanding ‘Human Error’, 3rd Edition*](https://learning.oreilly.com/library/view/the-field-guide/9781317031833/). CRC Press, November 2017. ISBN: 9781472439055

[[65](ch02.html#Allspaw2012-marker)] John Allspaw. [Blameless PostMortems and a Just Culture](https://www.etsy.com/codeascraft/blameless-postmortems/). *etsy.com*, May 2012. Archived at [perma.cc/YMJ7-NTAP](https://perma.cc/YMJ7-NTAP)

[[66](ch02.html#Sabo2023-marker)] Itzy Sabo. [Uptime Guarantees — A Pragmatic Perspective](https://world.hey.com/itzy/uptime-guarantees-a-pragmatic-perspective-736d7ea4). *world.hey.com*, March 2023. Archived at [perma.cc/F7TU-78JB](https://perma.cc/F7TU-78JB)

[[67](ch02.html#Jurewitz2013-marker)] Michael Jurewitz. [The Human Impact of Bugs](http://jury.me/blog/2013/3/14/the-human-impact-of-bugs). *jury.me*, March 2013. Archived at [perma.cc/5KQ4-VDYL](https://perma.cc/5KQ4-VDYL)

[[68](ch02.html#Siddique2021-marker)] Haroon Siddique and Ben Quinn. [Court clears 39 post office operators convicted due to ‘corrupt data’](https://www.theguardian.com/uk-news/2021/apr/23/court-clears-39-post-office-staff-convicted-due-to-corrupt-data). *theguardian.com*, April 2021. Archived at [archive.org](https://web.archive.org/web/20220630124107/https://www.theguardian.com/uk-news/2021/apr/23/court-clears-39-post-office-staff-convicted-due-to-corrupt-data)

[[69](ch02.html#Bohm2022-marker)] Nicholas Bohm, James Christie, Peter Bernard Ladkin, Bev Littlewood, Paul Marshall, Stephen Mason, Martin Newby, Steven J. Murdoch, Harold Thimbleby, and Martyn Thomas. [The legal rule that computers are presumed to be operating correctly – unforeseen and unjust consequences](https://www.benthamsgaze.org/wp-content/uploads/2022/06/briefing-presumption-that-computers-are-reliable.pdf). Briefing note, *benthamsgaze.org*, June 2022. Archived at [perma.cc/WQ6X-TMW4](https://perma.cc/WQ6X-TMW4)

[[70](ch02.html#McKinley2015-marker)] Dan McKinley. [Choose Boring Technology](https://mcfunley.com/choose-boring-technology). *mcfunley.com*, March 2015. Archived at [perma.cc/7QW7-J4YP](https://perma.cc/7QW7-J4YP)

[[71](ch02.html#Warfield2023-marker)] Andy Warfield. [Building and operating a pretty big storage system called S3](https://www.allthingsdistributed.com/2023/07/building-and-operating-a-pretty-big-storage-system.html). *allthingsdistributed.com*, July 2023. Archived at [perma.cc/7LPK-TP7V](https://perma.cc/7LPK-TP7V)

[[72](ch02.html#Brooker2023-marker)] Marc Brooker. [Surprising Scalability of Multitenancy](https://brooker.co.za/blog/2023/03/23/economics.html). *brooker.co.za*, March 2023. Archived at [archive.org](https://web.archive.org/web/20230404065818/https://brooker.co.za/blog/2023/03/23/economics.html)

[[73](ch02.html#Stopford2009-marker)] Ben Stopford. [Shared Nothing vs. Shared Disk Architectures: An Independent View](http://www.benstopford.com/2009/11/24/understanding-the-shared-nothing-architecture/). *benstopford.com*, November 2009. Archived at [perma.cc/7BXH-EDUR](https://perma.cc/7BXH-EDUR)

[[74](ch02.html#Stonebraker1986-marker)] Michael Stonebraker. [The Case for Shared Nothing](http://db.cs.berkeley.edu/papers/hpts85-nothing.pdf). *IEEE Database Engineering Bulletin*, volume 9, issue 1, pages 4–9, March 1986.

[[75](ch02.html#Antonopoulos2019_ch2-marker)] Panagiotis Antonopoulos, Alex Budovski, Cristian Diaconu, Alejandro Hernandez Saenz, Jack Hu, Hanuma Kodavalla, Donald Kossmann, Sandeep Lingam, Umar Farooq Minhas, Naveen Prakash, Vijendra Purohit, Hugh Qu, Chaitanya Sreenivas Ravella, Krystyna Reisteter, Sheetal Shrotri, Dixin Tang, and Vikram Wakade. [Socrates: The New SQL Server in the Cloud](https://www.microsoft.com/en-us/research/uploads/prod/2019/05/socrates.pdf). At *ACM International Conference on Management of Data* (SIGMOD), pages 1743–1756, June 2019. [doi:10.1145/3299869.3314047](https://doi.org/10.1145/3299869.3314047)

[[76](ch02.html#Newman2021_ch2-marker)] Sam Newman. [*Building Microservices*, second edition](https://www.oreilly.com/library/view/building-microservices-2nd/9781492034018/). O’Reilly Media, 2021. ISBN: 9781492034025

[[77](ch02.html#Ensmenger2016-marker)] Nathan Ensmenger. [When Good Software Goes Bad: The Surprising Durability of an Ephemeral Technology](https://themaintainers.wpengine.com/wp-content/uploads/2021/04/ensmenger-maintainers-v2.pdf). At *The Maintainers Conference*, April 2016. Archived at [perma.cc/ZXT4-HGZB](https://perma.cc/ZXT4-HGZB)

[[78](ch02.html#Glass2002-marker)] Robert L. Glass. [*Facts and Fallacies of Software Engineering*](https://learning.oreilly.com/library/view/facts-and-fallacies/0321117425/). Addison-Wesley Professional, October 2002. ISBN: 9780321117427

[[79](ch02.html#Bellotti2021-marker)] Marianne Bellotti. [*Kill It with Fire*](https://learning.oreilly.com/library/view/kill-it-with/9781098128883/). No Starch Press, April 2021. ISBN: 9781718501188

[[80](ch02.html#Bainbridge1983-marker)] Lisanne Bainbridge. [Ironies of automation](https://www.adaptivecapacitylabs.com/IroniesOfAutomation-Bainbridge83.pdf). *Automatica*, volume 19, issue 6, pages 775–779, November 1983. [doi:10.1016/0005-1098(83)90046-8](https://doi.org/10.1016/0005-1098(83)90046-8)

[[81](ch02.html#Hamilton2007-marker)] James Hamilton. [On Designing and Deploying Internet-Scale Services](https://www.usenix.org/legacy/events/lisa07/tech/full_papers/hamilton/hamilton.pdf). At *21st Large Installation System Administration Conference* (LISA), November 2007.

[[82](ch02.html#Horovits2021-marker)] Dotan Horovits. [Open Source for Better Observability](https://horovits.medium.com/open-source-for-better-observability-8c65b5630561). *horovits.medium.com*, October 2021. Archived at [perma.cc/R2HD-U2ZT](https://perma.cc/R2HD-U2ZT)

[[83](ch02.html#Foote1997-marker)] Brian Foote and Joseph Yoder. [Big Ball of Mud](http://www.laputan.org/pub/foote/mud.pdf). At *4th Conference on Pattern Languages of Programs* (PLoP), September 1997. Archived at [perma.cc/4GUP-2PBV](https://perma.cc/4GUP-2PBV)

[[84](ch02.html#Brooker2022-marker)] Marc Brooker. [What is a simple system?](https://brooker.co.za/blog/2022/05/03/simplicity.html) *brooker.co.za*, May 2022. Archived at [archive.org](https://web.archive.org/web/20220602141902/https://brooker.co.za/blog/2022/05/03/simplicity.html)

[[85](ch02.html#Brooks1995-marker)] Frederick P Brooks. [No Silver Bullet – Essence and Accident in Software Engineering](http://worrydream.com/refs/Brooks-NoSilverBullet.pdf). In [*The Mythical Man-Month*](https://www.oreilly.com/library/view/mythical-man-month-the/0201835959/), Anniversary edition, Addison-Wesley, 1995. ISBN: 9780201835953

[[86](ch02.html#Luu2020-marker)] Dan Luu. [Against essential and accidental complexity](https://danluu.com/essential-complexity/). *danluu.com*, December 2020. Archived at [perma.cc/H5ES-69KC](https://perma.cc/H5ES-69KC)

[[87](ch02.html#Gamma1994-marker)] Erich Gamma, Richard Helm, Ralph Johnson, and John Vlissides. [*Design Patterns: Elements of Reusable Object-Oriented Software*](https://learning.oreilly.com/library/view/design-patterns-elements/0201633612/). Addison-Wesley Professional, October 1994. ISBN: 9780201633610

[[88](ch02.html#Evans2003-marker)] Eric Evans. [*Domain-Driven Design: Tackling Complexity in the Heart of Software*](https://learning.oreilly.com/library/view/domain-driven-design-tackling/0321125215/). Addison-Wesley Professional, August 2003. ISBN: 9780321125217

[[89](ch02.html#Breivold2008-marker)] Hongyu Pei Breivold, Ivica Crnkovic, and Peter J. Eriksson. [Analyzing Software Evolvability](http://www.es.mdh.se/pdf_publications/1251.pdf). at *32nd Annual IEEE International Computer Software and Applications Conference* (COMPSAC), July 2008. [doi:10.1109/COMPSAC.2008.50](https://doi.org/10.1109/COMPSAC.2008.50)

[[90](ch02.html#Zaninotto2002-marker)] Enrico Zaninotto. [From X programming to the X organisation](https://martinfowler.com/articles/zaninotto.pdf). At *XP Conference*, May 2002. Archived at [perma.cc/R9AR-QCKZ](https://perma.cc/R9AR-QCKZ)


------

| 上一章                        | 目錄                     | 下一章                    |
|----------------------------|------------------------|------------------------|
| [第一章：資料系統架構中的利弊權衡](ch1.md) | [設計資料密集型應用](README.md) | [第二章：定義非功能性要求](ch3.md) |