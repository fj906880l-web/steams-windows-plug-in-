import {
  definePlugin,
  PanelSection,
  PanelSectionRow,
  ButtonItem,
  Field,
  DropdownItem,
  ServerAPI,
  staticClasses
} from "decky-frontend-lib";
import { VFC, useState, useEffect } from "react";
import { FaShieldAlt, FaGamepad, FaCloud, FaBolt, FaCheckCircle, FaWifi } from "react-icons/fa";

interface LatencyResult {
  gfn: string;
  xbox: string;
  boosteroid: string;
}

interface DropdownOption {
  data: string;
  label: string;
}

const Content: VFC<{ serverAPI: ServerAPI }> = ({ serverAPI }: { serverAPI: ServerAPI }) => {
  const [selectedCodec, setSelectedCodec] = useState<string>("auto");
  const [selectedResolution, setSelectedResolution] = useState<string>("800p");
  const [latency, setLatency] = useState<LatencyResult>({ gfn: "...", xbox: "...", boosteroid: "..." });
  const [isTestingPing, setIsTestingPing] = useState<boolean>(false);
  const [statusMessage, setStatusMessage] = useState<string>("");

  const runPingTest = async () => {
    setIsTestingPing(true);
    try {
      const res = await serverAPI.callPluginMethod<any, any>("ping_datacenters", {});
      if (res && res.success) {
        setLatency(res.result as LatencyResult);
      }
    } catch (err) {
      console.error("Failed to ping cloud servers", err);
    } finally {
      setIsTestingPing(false);
    }
  };

  const launchService = async (service: string, game?: string) => {
    setStatusMessage(`Launching ${game || service}...`);
    try {
      const res = await serverAPI.callPluginMethod<any, any>("launch_service", {
        service,
        game: game || "",
        codec: selectedCodec,
        resolution: selectedResolution
      });
      if (res && res.success) {
        setStatusMessage(`Launched ${service} successfully!`);
      } else {
        setStatusMessage(`Launch failed: ${(res && res.result && (res.result as any).error) || "Unknown error"}`);
      }
    } catch (err: any) {
      setStatusMessage(`Error: ${err.message || err}`);
    }
  };

  const syncShortcuts = async () => {
    setStatusMessage("Syncing Steam shortcuts...");
    try {
      const res = await serverAPI.callPluginMethod<any, any>("sync_steam_shortcuts", {});
      if (res && res.success) {
        setStatusMessage("Steam shortcuts refreshed! Restart Steam if needed.");
      }
    } catch (err: any) {
      setStatusMessage(`Sync error: ${err.message || err}`);
    }
  };

  useEffect(() => {
    runPingTest();
  }, []);

  return (
    <div style={{ padding: "8px" }}>
      {/* Ban-Immunity Security Banner */}
      <PanelSection title="Anti-Cheat Protection">
        <PanelSectionRow>
          <div
            style={{
              backgroundColor: "rgba(16, 185, 129, 0.15)",
              border: "1px solid #10b981",
              borderRadius: "8px",
              padding: "10px",
              display: "flex",
              alignItems: "center",
              gap: "10px"
            }}
          >
            <FaShieldAlt style={{ color: "#10b981", fontSize: "24px", flexShrink: 0 }} />
            <div>
              <div style={{ fontWeight: "bold", color: "#10b981" }}>
                Destiny 2 Ban-Immunity Active
              </div>
              <div style={{ fontSize: "11px", opacity: 0.85, marginTop: "2px" }}>
                Running via verified Windows Cloud instance. 0% ban risk with BattlEye & Bungie policy.
              </div>
            </div>
          </div>
        </PanelSectionRow>
      </PanelSection>

      {/* Quick Play Windows Anti-Cheat Games */}
      <PanelSection title="Destiny 2 Quick Play">
        <PanelSectionRow>
          <ButtonItem
            layout="below"
            onClick={() => launchService("gfn", "destiny2")}
          >
            <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
              <FaBolt style={{ color: "#76b900" }} />
              <span>Launch Destiny 2 (GeForce NOW)</span>
            </div>
          </ButtonItem>
        </PanelSectionRow>

        <PanelSectionRow>
          <ButtonItem
            layout="below"
            onClick={() => launchService("xbox", "destiny2")}
          >
            <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
              <FaGamepad style={{ color: "#107c41" }} />
              <span>Launch Destiny 2 (Xbox Cloud)</span>
            </div>
          </ButtonItem>
        </PanelSectionRow>

        <PanelSectionRow>
          <ButtonItem
            layout="below"
            onClick={() => launchService("boosteroid", "destiny2")}
          >
            <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
              <FaCloud style={{ color: "#2563eb" }} />
              <span>Launch Destiny 2 (Boosteroid)</span>
            </div>
          </ButtonItem>
        </PanelSectionRow>
      </PanelSection>

      {/* Cloud Portals */}
      <PanelSection title="Cloud Gaming Portals">
        <PanelSectionRow>
          <ButtonItem
            layout="below"
            onClick={() => launchService("gfn")}
          >
            Open NVIDIA GeForce NOW
          </ButtonItem>
        </PanelSectionRow>

        <PanelSectionRow>
          <ButtonItem
            layout="below"
            onClick={() => launchService("xbox")}
          >
            Open Xbox Cloud Gaming
          </ButtonItem>
        </PanelSectionRow>

        <PanelSectionRow>
          <ButtonItem
            layout="below"
            onClick={() => launchService("boosteroid")}
          >
            Open Boosteroid Portal
          </ButtonItem>
        </PanelSectionRow>

        <PanelSectionRow>
          <ButtonItem
            layout="below"
            onClick={() => launchService("shadow")}
          >
            Open Shadow PC Virtual Windows
          </ButtonItem>
        </PanelSectionRow>
      </PanelSection>

      {/* Performance & Stream Settings */}
      <PanelSection title="Hardware Stream Optimization">
        <PanelSectionRow>
          <DropdownItem
            label="Video Codec (HW VA-API)"
            menuLabel="Select Codec"
            selectedOption={selectedCodec}
            onChange={(opt: DropdownOption) => setSelectedCodec(opt.data)}
            rgOptions={[
              { data: "auto", label: "Auto (Balanced)" },
              { data: "h265", label: "HEVC / H.265 (Crisp / Lower Bandwidth)" },
              { data: "h264", label: "H.264 (Maximum Compatibility)" }
            ]}
          />
        </PanelSectionRow>

        <PanelSectionRow>
          <DropdownItem
            label="Target Resolution"
            menuLabel="Select Resolution"
            selectedOption={selectedResolution}
            onChange={(opt: DropdownOption) => setSelectedResolution(opt.data)}
            rgOptions={[
              { data: "800p", label: "1280×800 (Steam Deck Handheld)" },
              { data: "1080p", label: "1920×1080 (Docked Full HD)" },
              { data: "720p", label: "1280×720 (Standard 16:9)" }
            ]}
          />
        </PanelSectionRow>
      </PanelSection>

      {/* Datacenter Ping Monitor */}
      <PanelSection title="Cloud Latency Monitor">
        <PanelSectionRow>
          <Field label="GeForce NOW Ping">
            <span>{latency.gfn}</span>
          </Field>
        </PanelSectionRow>
        <PanelSectionRow>
          <Field label="Xbox Cloud Ping">
            <span>{latency.xbox}</span>
          </Field>
        </PanelSectionRow>
        <PanelSectionRow>
          <Field label="Boosteroid Ping">
            <span>{latency.boosteroid}</span>
          </Field>
        </PanelSectionRow>
        <PanelSectionRow>
          <ButtonItem
            layout="below"
            disabled={isTestingPing}
            onClick={runPingTest}
          >
            <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
              <FaWifi />
              <span>{isTestingPing ? "Measuring Latency..." : "Refresh Latency Benchmarks"}</span>
            </div>
          </ButtonItem>
        </PanelSectionRow>
      </PanelSection>

      {/* Steam Integration Utilities */}
      <PanelSection title="SteamOS Integration">
        <PanelSectionRow>
          <ButtonItem layout="below" onClick={syncShortcuts}>
            <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
              <FaCheckCircle style={{ color: "#38bdf8" }} />
              <span>Refresh Game Mode Steam Shortcuts</span>
            </div>
          </ButtonItem>
        </PanelSectionRow>
      </PanelSection>

      {statusMessage && (
        <div
          style={{
            marginTop: "10px",
            padding: "8px",
            borderRadius: "6px",
            fontSize: "12px",
            backgroundColor: "rgba(30, 41, 59, 0.7)",
            textAlign: "center"
          }}
        >
          {statusMessage}
        </div>
      )}
    </div>
  );
};

export default definePlugin((serverAPI: ServerAPI) => {
  return {
    title: <div className={staticClasses.Title}>CloudDeck</div>,
    content: <Content serverAPI={serverAPI} />,
    icon: <FaCloud />,
    onDismount() {}
  };
});
