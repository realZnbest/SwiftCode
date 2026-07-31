import Foundation

/// The three languages the game supports.
enum AppLanguage: String, CaseIterable, Codable {
    case thai
    case english
    case chinese

    /// Shown as the button label on the language-select screen (never needs translating).
    var nativeName: String {
        switch self {
        case .thai: return "ไทย"
        case .english: return "English"
        case .chinese: return "中文"
        }
    }
}

/// -----------------------------------------------------------------------
/// ALL GAME TEXT LIVES HERE.
///
/// Thai (`th`) is already filled in for every line. The `en` and `zh` values
/// below are just placeholders (currently a duplicate of the Thai text) so the
/// game never shows a blank label — replace them with real English / Chinese
/// translations whenever you're ready. Nothing else needs to change: once you
/// edit the strings in this file, they show up in the game automatically.
/// -----------------------------------------------------------------------
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

    // MARK: - Title

    static let titleName = Entry(th: "TRASHER", en: "TRASHER", zh: "TRASHER")
    static let titleSubtitle = Entry(th: "a plastic bottle's journey", en: "a plastic bottle's journey", zh: "a plastic bottle's journey")
    static let titleTapToBegin = Entry(th: "แตะเพื่อเริ่ม", en: "แตะเพื่อเริ่ม", zh: "แตะเพื่อเริ่ม")

    // MARK: - Scene narration lines

    static let factoryOriginLine = Entry(th: "มันถูกผลิตมา เพื่อใช้เพียงครั้งเดียว", en: "มันถูกผลิตมา เพื่อใช้เพียงครั้งเดียว", zh: "มันถูกผลิตมา เพื่อใช้เพียงครั้งเดียว")
    static let deliveryTruckLine = Entry(th: "กำลังเดินทางไปที่ไหนสักแห่ง", en: "กำลังเดินทางไปที่ไหนสักแห่ง", zh: "กำลังเดินทางไปที่ไหนสักแห่ง")
    static let vendingDiscardLine = Entry(th: "มันถูกใช้ครั้งเดียว แล้วก็โดนทิ้ง", en: "มันถูกใช้ครั้งเดียว แล้วก็โดนทิ้ง", zh: "มันถูกใช้ครั้งเดียว แล้วก็โดนทิ้ง")
    static let vendingBuyButton = Entry(th: "กดน้ำ", en: "กดน้ำ", zh: "กดน้ำ")
    static let streetIntroLine = Entry(th: "มันไร้ค่า เกะกะขวางทางทุกคน", en: "มันไร้ค่า เกะกะขวางทางทุกคน", zh: "มันไร้ค่า เกะกะขวางทางทุกคน")
    static let streetDogLine = Entry(th: "แม้กระทั่งหมา", en: "แม้กระทั่งหมา", zh: "แม้กระทั่งหมา")
    static let streetNoShovelWarning = Entry(th: "ไม่มีเสียมให้ขุดแล้ว ลองไปดูที่ท่อระบายน้ำสิ", en: "ไม่มีเสียมให้ขุดแล้ว ลองไปดูที่ท่อระบายน้ำสิ", zh: "ไม่มีเสียมให้ขุดแล้ว ลองไปดูที่ท่อระบายน้ำสิ")
    static let stormDrainLine = Entry(th: "ดำดิ่งสู่ความมืดมิด จนไม่มีใครมองเห็น", en: "ดำดิ่งสู่ความมืดมิด จนไม่มีใครมองเห็น", zh: "ดำดิ่งสู่ความมืดมิด จนไม่มีใครมองเห็น")
    static let landfillFailureLine = Entry(th: "การฝังไม่ได้ทำให้หายไปไหน", en: "การฝังไม่ได้ทำให้หายไปไหน", zh: "การฝังไม่ได้ทำให้หายไปไหน")
    static let secondBottleMirrorLine = Entry(th: "ไม่ใช่ทุกชิ้นที่จะออกมาได้", en: "ไม่ใช่ทุกชิ้นที่จะออกมาได้", zh: "ไม่ใช่ทุกชิ้นที่จะออกมาได้")
    static let canalLine = Entry(th: "บางส่วนของมันหลุดออกไปและไม่เคยกลับมา", en: "บางส่วนของมันหลุดออกไปและไม่เคยกลับมา", zh: "บางส่วนของมันหลุดออกไปและไม่เคยกลับมา")
    static let canalNoRaftWarning = Entry(th: "ขวดน้ำมันลอยไปแล้ว มาลองรีไซเคิลกันเถอะ", en: "ขวดน้ำมันลอยไปแล้ว มาลองรีไซเคิลกันเถอะ", zh: "ขวดน้ำมันลอยไปแล้ว มาลองรีไซเคิลกันเถอะ")
    static let seaFailureLine = Entry(th: "มันไม่ได้หายไปไหน", en: "มันไม่ได้หายไปไหน", zh: "มันไม่ได้หายไปไหน")
    static let nightIntoDayLine = Entry(th: "เมื่อเวลาผ่านไป", en: "เมื่อเวลาผ่านไป", zh: "เมื่อเวลาผ่านไป")
    static let fishingNetCollectButton = Entry(th: "เก็บขวด", en: "เก็บขวด", zh: "เก็บขวด")
    static let sortingLineLine = Entry(th: "มันถูกเข้ากระบวนการคัดแยก", en: "มันถูกเข้ากระบวนการคัดแยก", zh: "มันถูกเข้ากระบวนการคัดแยก")
    static let recyclingWrongBinWarning = Entry(th: "ถังขยะใบนี้มีแต่จะทำให้มันถูกฝัง ลองเอาไปรีไซเคิลดูสิ!", en: "ถังขยะใบนี้มีแต่จะทำให้มันถูกฝัง ลองเอาไปรีไซเคิลดูสิ!", zh: "ถังขยะใบนี้มีแต่จะทำให้มันถูกฝัง ลองเอาไปรีไซเคิลดูสิ!")
    static let recyclingBenchCaption = Entry(th: "ดูนี่สิ! ตอนนี้มันกลายเป็นม้านั่งที่ทำจากพลาสติกรีไซเคิลแล้ว", en: "ดูนี่สิ! ตอนนี้มันกลายเป็นม้านั่งที่ทำจากพลาสติกรีไซเคิลแล้ว", zh: "ดูนี่สิ! ตอนนี้มันกลายเป็นม้านั่งที่ทำจากพลาสติกรีไซเคิลแล้ว")
    static let binLabelTrash = Entry(th: "ถังขยะ", en: "ถังขยะ", zh: "ถังขยะ")
    static let binLabelRecycle = Entry(th: "รีไซเคิล", en: "รีไซเคิล", zh: "รีไซเคิล")
    static let pelletRevealLine = Entry(th: "ส่วนชิ้นนี้มันไม่ได้เหมือนเดิม แต่ก็ไม่ได้หายไปไหน", en: "ส่วนชิ้นนี้มันไม่ได้เหมือนเดิม แต่ก็ไม่ได้หายไปไหน", zh: "ส่วนชิ้นนี้มันไม่ได้เหมือนเดิม แต่ก็ไม่ได้หายไปไหน")
    static let truckDeliveryLine = Entry(th: "เส้นทางนี้จะทำให้มันเปลี่ยนไป", en: "เส้นทางนี้จะทำให้มันเปลี่ยนไป", zh: "เส้นทางนี้จะทำให้มันเปลี่ยนไป")
    static let montageCity = Entry(th: "ในเมือง", en: "ในเมือง", zh: "ในเมือง")
    static let montageRiver = Entry(th: "ในน้ำ", en: "ในน้ำ", zh: "ในน้ำ")
    static let montageEverywhere = Entry(th: "ทุกๆที่", en: "ทุกๆที่", zh: "ทุกๆที่")
    static let communityCleanupLine = Entry(th: "มีมือบางคู่ เลือกที่จะหยุดไม่ให้มันต้องมาเริ่มเส้นทางนี้อีก", en: "มีมือบางคู่ เลือกที่จะหยุดไม่ให้มันต้องมาเริ่มเส้นทางนี้อีก", zh: "มีมือบางคู่ เลือกที่จะหยุดไม่ให้มันต้องมาเริ่มเส้นทางนี้อีก")
    static let endingBenchCaption = Entry(th: "พลาสติกใหม่ที่ทำจากพลาสติกเดิม", en: "พลาสติกใหม่ที่ทำจากพลาสติกเดิม", zh: "พลาสติกใหม่ที่ทำจากพลาสติกเดิม")
    static let endingFinalLine = Entry(th: "ขยะไม่ได้หายไปไหน\nแต่คุณเลือกได้ว่าจะให้มันไปอยู่ไหน", en: "ขยะไม่ได้หายไปไหน\nแต่คุณเลือกได้ว่าจะให้มันไปอยู่ไหน", zh: "ขยะไม่ได้หายไปไหน\nแต่คุณเลือกได้ว่าจะให้มันไปอยู่ไหน")
    static let endingPlayAgainButton = Entry(th: "เล่นอีกครั้ง", en: "เล่นอีกครั้ง", zh: "เล่นอีกครั้ง")

    // MARK: - Path choice labels (Effects.swift PathKind)

    static let pathLandfill = Entry(th: "ฝังดิน", en: "ฝังดิน", zh: "ฝังดิน")
    static let pathStormDrain = Entry(th: "ท่อระบายน้ำ", en: "ท่อระบายน้ำ", zh: "ท่อระบายน้ำ")
    static let pathSea = Entry(th: "ล่องลอยต่อไป", en: "ล่องลอยต่อไป", zh: "ล่องลอยต่อไป")
    static let pathRecyclingPoint = Entry(th: "รีไซเคิล", en: "รีไซเคิล", zh: "รีไซเคิล")
}

extension GameState {
    /// Convenience: look up an `Loc.Entry` in the currently selected language.
    func t(_ entry: Loc.Entry) -> String {
        entry.text(for: language)
    }
}
