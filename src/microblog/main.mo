import Int "mo:base/Int";
import List "mo:base/List";
import Iter "mo:base/Iter";
import Time "mo:base/Time";
import Principal "mo:base/Principal";

actor {
    public type Message = {
        msg : Text;
        time : Time.Time;
    };

    public type Microblog = actor {
        follow: shared(Principal) -> async (); //添加关注对象
        follows: shared query () -> async [Principal]; //返回关注列表
        post: shared (Text) -> async (); // 发布新消息
        posts: shared query (Time.Time) -> async [Message]; //返回所有发布的消息
        timeline: shared (Time.Time) -> async [Message]; //返回所有关注对象发布的消息
    };

    stable var followed : List.List<Principal> = List.nil();

    public shared func follow(id: Principal) : async () {
        followed := List.push(id, followed);
    };

    public shared query func follows() : async [Principal] {
        List.toArray(followed)
    };

    stable var messages : List.List<Message> = List.nil();

    public shared func post(text: Text) : async () {
        let message = {
            msg = text;
            time = Time.now();
        };
        messages := List.push(message, messages)
    };

    public shared query func posts(since:Time.Time) : async [Message] {
        var posts_after : List.List<Message> = List.nil();

        for (msg in Iter.fromList(messages)){
            if (Int.greater(msg.time,since)){
                posts_after := List.push(msg, posts_after);
            };
        };
        List.toArray(posts_after)
    };

    public shared func timeline(since:Time.Time) : async [Message] {
        var all : List.List<Message> = List.nil();

        for (id in Iter.fromList(followed)){
            let canister : Microblog = actor(Principal.toText(id));
            let msgs = await canister.posts(since);
                for (msg in Iter.fromArray(msgs)){
                if (Int.greater(msg.time,since)){
                    all := List.push(msg, all);
                };
            };
        };
        List.toArray(all)
    };
};
