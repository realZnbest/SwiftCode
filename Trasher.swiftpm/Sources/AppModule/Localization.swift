import Foundation

enum AppLanguage: String, CaseIterable, Codable, Hashable {
    case thai
    case english
    case chinese

    var nativeName: String {
        switch self {
        case .thai: return "ไทย"
        case .english: return "English"
        case .chinese: return "中文"
        }
    }
}

enum Loc {
    struct Entry {
        let th: String
        let en: String
        let zh: String

        func text(for language: AppLanguage) -> String {
            switch language {
            case .thai: return th
            case .english: return en
            case .chinese: return zh
            }
        }
    }

    static let titleName = Entry(th: "TRASHER", en: "TRASHER", zh: "TRASHER")
    static let titleSubtitle = Entry(th: "a plastic bottle's journey", en: "a plastic bottle's journey", zh: "一颗塑料瓶的旅程")
    static let titleTapToBegin = Entry(th: "แตะเพื่อเริ่ม", en: "Tap to Begin", zh: "轻触，开始这段旅程")
    static let titleBackToLanguage = Entry(th: "ย้อนกลับ", en: "Back", zh: "返回")

    static let factoryOriginLine = Entry(
        th: "มันถูกผลิตมา เพื่อใช้เพียงครั้งเดียว",
        en: "It was born for a single use.",
        zh: "它被造出来，只为了活这一次。"
    )
    static let deliveryTruckLine = Entry(
        th: "กำลังเดินทางไปที่ไหนสักแห่ง",
        en: "Riding onward, toward some nameless somewhere.",
        zh: "驶向一个连自己都不知道的远方。"
    )
    static let vendingDiscardLine = Entry(
        th: "มันถูกใช้ครั้งเดียว แล้วก็โดนทิ้ง",
        en: "Used once, then tossed aside.",
        zh: "只用了一次，便被随手丢弃。"
    )
    static let vendingBuyButton = Entry(th: "กดน้ำ", en: "Buy a Drink", zh: "买一瓶")
    static let streetIntroLine = Entry(
        th: "มันไร้ค่า เกะกะขวางทางทุกคน",
        en: "Worthless now, it just gets in everyone's way.",
        zh: "如今一文不值，只会碍着所有人的路。"
    )
    static let streetDogLine = Entry(
        th: "แม้กระทั่งหมา",
        en: "Even the dog won't give it a second look.",
        zh: "连狗都懒得多看它一眼。"
    )
    static let dragBottleHint = Entry(
        th: "ลากขวดไปหา",
        en: "Drag the bottle",
        zh: "拖动瓶子"
    )
    static let streetNoShovelWarning = Entry(
        th: "ไม่มีเสียมให้ขุดแล้ว ลองไปดูที่ท่อระบายน้ำสิ",
        en: "No shovel left to dig with. Try the storm drain instead.",
        zh: "已经没有铲子能挖了，去看看那边的排水管道吧。"
    )
    static let stormDrainLine = Entry(
        th: "ดำดิ่งสู่ความมืดมิด จนไม่มีใครมองเห็น",
        en: "Down it sinks, into a dark no one can see.",
        zh: "一路沉入无人能望见的黑暗深处。"
    )
    static let landfillFailureLine = Entry(
        th: "การฝังไม่ได้ทำให้หายไปไหน",
        en: "Burying it doesn't make it disappear.",
        zh: "埋进土里，并不会让它真正消失。"
    )
    static let secondBottleMirrorLine = Entry(
        th: "ไม่ใช่ทุกชิ้นที่จะออกมาได้",
        en: "Not every piece finds its way back out.",
        zh: "不是每一片碎片，都能重见天日。"
    )
    static let canalLine = Entry(
        th: "บางส่วนของมันหลุดออกไปและไม่เคยกลับมา",
        en: "A part of it broke free, and never came back.",
        zh: "它的一部分脱落了，从此再没有回来过。"
    )
    static let canalNoRaftWarning = Entry(
        th: "ขวดน้ำมันลอยไปแล้ว มาลองรีไซเคิลกันเถอะ",
        en: "The bottle's already drifted off. Let's try recycling instead.",
        zh: "瓶子已经漂走了，不如试着把它送去回收吧。"
    )
    static let seaFailureLine = Entry(
        th: "มันไม่ได้หายไปไหน",
        en: "It never really goes away.",
        zh: "它从未真正消失过。"
    )
    static let nightIntoDayLine = Entry(
        th: "เมื่อเวลาผ่านไป",
        en: "Time slipped quietly by.",
        zh: "时间，就这样悄悄流走。"
    )
    static let fishingNetCollectButton = Entry(th: "เก็บขวด", en: "Reel It In", zh: "捞起它")
    static let sortingLineLine = Entry(
        th: "ถึงเวลาที่มันจะถูกคัดแยก",
        en: "Onto the sorting line it goes.",
        zh: "它被送上了分拣的流水线。"
    )
    static let recyclingWrongBinWarning = Entry(
        th: "ถังขยะใบนี้มีแต่จะทำให้มันถูกฝัง ลองเอาไปรีไซเคิลดูสิ!",
        en: "That bin only leads to burial. Try recycling instead!",
        zh: "这个桶只会让它被埋进土里，试试送去回收吧！"
    )
    static let recyclingBenchCaption = Entry(
        th: "ดูนี่สิ! ตอนนี้มันกลายเป็นม้านั่งที่ทำจากพลาสติกรีไซเคิลแล้ว",
        en: "Look at that, reborn as a bench, made of recycled plastic.",
        zh: "你看！它如今变成了一张回收塑料做的长椅。"
    )
    static let binLabelTrash = Entry(th: "ถังขยะ", en: "Trash", zh: "垃圾桶")
    static let binLabelRecycle = Entry(th: "รีไซเคิล", en: "Recycle", zh: "回收桶")
    static let pelletRevealLine = Entry(
        th: "ส่วนชิ้นนี้มันไม่ได้เหมือนเดิม แต่ก็ไม่ได้หายไปไหน",
        en: "It isn't what it used to be. But it hasn't vanished, either.",
        zh: "这一块，已经不再是原来的模样，但它也从未真正消失。"
    )
    static let truckDeliveryLine = Entry(
        th: "เส้นทางนี้จะทำให้มันเปลี่ยนไป",
        en: "This road will change everything about it.",
        zh: "这条路，会让它彻底不同。"
    )
    static let montageCity = Entry(th: "ในเมือง", en: "In the City", zh: "在城市里")
    static let montageRiver = Entry(th: "ในน้ำ", en: "In the Water", zh: "在水流中")
    static let montageEverywhere = Entry(th: "ทุกๆที่", en: "Everywhere", zh: "无处不在")
    static let communityCleanupLine = Entry(
        th: "มีมือบางคู่ เลือกที่จะหยุดไม่ให้มันต้องมาเริ่มเส้นทางนี้อีก",
        en: "Somewhere, a pair of hands chose to stop this story from starting over.",
        zh: "曾有一双手，选择了不让它再一次踏上这条路。"
    )
    static let endingBenchCaption = Entry(
        th: "พลาสติกใหม่ที่ทำจากพลาสติกเดิม",
        en: "New plastic, born from the old.",
        zh: "用旧的塑料，造出新的模样。"
    )
    static let endingFinalLine = Entry(
        th: "ขยะไม่ได้หายไปไหน\nแต่คุณเลือกได้ว่าจะให้มันไปอยู่ไหน",
        en: "Trash never really disappears.\nBut you get to decide where it goes.",
        zh: "垃圾从未真正消失。\n只是，它的去向，由你决定。"
    )
    static let endingPlayAgainButton = Entry(th: "เล่นอีกครั้ง", en: "Play Again", zh: "再玩一次")

    static let pathLandfill = Entry(th: "ฝังดิน", en: "Landfill", zh: "掩埋")
    static let pathStormDrain = Entry(th: "ท่อระบายน้ำ", en: "Storm Drain", zh: "排水道")
    static let pathSea = Entry(th: "ล่องลอยต่อไป", en: "Drift On", zh: "继续漂流")
    static let pathRecyclingPoint = Entry(th: "รีไซเคิล", en: "Recycle", zh: "回收")
}

extension GameState {
    func t(_ entry: Loc.Entry) -> String {
        entry.text(for: language)
    }
}
