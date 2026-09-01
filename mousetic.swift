import Foundation

guard CommandLine.arguments.count > 1 else {
    fputs("Usage: haptic-hook <waveform>\n", stderr)
    exit(1)
}

let waveform = CommandLine.arguments[1]
let url = URL(string: "https://local.jmw.nz:41443/haptic/\(waveform)")!
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.setValue("0", forHTTPHeaderField: "Content-Length")
request.httpBody = Data()

let semaphore = DispatchSemaphore(value: 0)
URLSession.shared.dataTask(with: request) { _, _, _ in
    semaphore.signal()
}.resume()
semaphore.wait()
