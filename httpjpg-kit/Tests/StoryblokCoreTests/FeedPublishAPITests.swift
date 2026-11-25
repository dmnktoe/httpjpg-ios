import XCTest

@testable import StoryblokCore

final class FeedPublishAPITests: XCTestCase {
    func testTheMultipartBodySendsTheSignedFieldsThenTheFile() throws {
        let body = FeedPublishAPI.multipartBody(
            fields: ["key": "f/42/a.jpg", "acl": "public-read"],
            file: Data("PIXELS".utf8),
            filename: "post-1.jpg",
            contentType: "image/jpeg",
            boundary: "b0"
        )
        let text = try XCTUnwrap(String(data: body, encoding: .utf8))

        XCTAssertEqual(
            text,
            "--b0\r\nContent-Disposition: form-data; name=\"acl\"\r\n\r\npublic-read\r\n"
                + "--b0\r\nContent-Disposition: form-data; name=\"key\"\r\n\r\nf/42/a.jpg\r\n"
                + "--b0\r\nContent-Disposition: form-data; name=\"file\"; filename=\"post-1.jpg\"\r\n"
                + "Content-Type: image/jpeg\r\n\r\nPIXELS\r\n--b0--\r\n"
        )
    }

    func testAFilenameCannotBreakOutOfItsHeader() throws {
        let body = FeedPublishAPI.multipartBody(
            fields: [:],
            file: Data(),
            filename: "a\".jpg",
            contentType: "image/jpeg",
            boundary: "b0"
        )
        let text = try XCTUnwrap(String(data: body, encoding: .utf8))

        XCTAssertTrue(text.contains("filename=\"a.jpg\""))
    }

    func testRefusalsMapToWhatTheComposerShows() {
        XCTAssertEqual(FeedPublishAPI.error(status: 401, body: Data()), .unauthorized)
        XCTAssertEqual(FeedPublishAPI.error(status: 503, body: Data()), .notConfigured)
        XCTAssertEqual(
            FeedPublishAPI.error(
                status: 400,
                body: Data(#"{"error":"invalid_body","message":"format must be one of 1/1, 4/5, original"}"#.utf8)
            ),
            .rejected("format must be one of 1/1, 4/5, original")
        )
        XCTAssertEqual(FeedPublishAPI.error(status: 502, body: Data("nope".utf8)), .http(status: 502))
    }

    func testAPhotoPostEncodesAsTheSiteExpects() throws {
        let request = FeedPublishRequest(
            caption: "harbour",
            format: .portrait,
            images: [
                FeedPublishRequest.Image(assetId: 7, fit: .cover),
                FeedPublishRequest.Image(assetId: 8, fit: .contain, alt: "Ferry"),
            ],
            clientId: "0F5C1A2B-9D3E-4F60-8A7B-112233445566",
            date: Date(timeIntervalSince1970: 1_795_620_612)
        )

        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any]
        )
        XCTAssertEqual(json["caption"] as? String, "harbour")
        XCTAssertEqual(json["format"] as? String, "4/5")
        XCTAssertNil(json["music"])
        XCTAssertEqual(json["clientId"] as? String, "0F5C1A2B-9D3E-4F60-8A7B-112233445566")
        XCTAssertEqual(json["date"] as? String, FeedPublishRequest.timestamp(Date(timeIntervalSince1970: 1_795_620_612)))
        let images = try XCTUnwrap(json["images"] as? [[String: Any]])
        XCTAssertEqual(images.map { $0["assetId"] as? Int }, [7, 8])
        XCTAssertEqual(images.map { $0["fit"] as? String }, ["cover", "contain"])
        XCTAssertNil(images[0]["alt"])
        XCTAssertEqual(images[1]["alt"] as? String, "Ferry")
    }

    func testAMusicPostEncodesItsSourceAndOnlyTheFieldsItHas() throws {
        let request = FeedPublishRequest(
            caption: "",
            format: .square,
            images: [],
            music: FeedPublishRequest.Music(source: .mp3, assetId: 11, title: "mega mashup"),
            clientId: "draft-0001",
            date: Date(timeIntervalSince1970: 0)
        )

        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any]
        )
        let music = try XCTUnwrap(json["music"] as? [String: Any])
        XCTAssertEqual(music["source"] as? String, "mp3")
        XCTAssertEqual(music["assetId"] as? Int, 11)
        XCTAssertEqual(music["title"] as? String, "mega mashup")
        XCTAssertNil(music["src"])
        XCTAssertNil(music["artist"])
    }

    func testTheDateIsSentInUTCToTheSecond() {
        XCTAssertEqual(FeedPublishRequest.timestamp(Date(timeIntervalSince1970: 0)), "1970-01-01T00:00:00Z")
    }

    func testOnlyTheRoutesOwnAnswerConfirmsASession() {
        XCTAssertTrue(FeedPublishAPI.confirmsSession(Data(#"{"ok":true}"#.utf8)))
        XCTAssertFalse(FeedPublishAPI.confirmsSession(Data(#"{"ok":false}"#.utf8)))
        XCTAssertFalse(FeedPublishAPI.confirmsSession(Data("<!DOCTYPE html><html>".utf8)))
        XCTAssertFalse(FeedPublishAPI.confirmsSession(Data()))
    }

    func testASignedUploadDecodesFromTheSitesAnswer() throws {
        let upload = try JSONDecoder().decode(
            FeedPublishAPI.SignedUpload.self,
            from: Data(#"{"id":7,"uploadUrl":"https://s3.test/bucket","fields":{"key":"f/42/a.jpg"}}"#.utf8)
        )

        XCTAssertEqual(upload.id, 7)
        XCTAssertEqual(upload.uploadURL.absoluteString, "https://s3.test/bucket")
        XCTAssertEqual(upload.fields, ["key": "f/42/a.jpg"])
    }
}
