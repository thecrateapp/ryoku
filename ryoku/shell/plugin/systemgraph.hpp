#pragma once

#include "systemmonitor.hpp"

#include <QColor>
#include <QPointer>
#include <QQuickItem>
#include <QStringList>
#include <QTimer>
#include <QVariantList>
#include <QVector>
#include <qqmlregistration.h>

#include <array>
#include <atomic>

class SystemGraph : public QQuickItem {
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(SystemMonitor* source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(bool active READ active WRITE setActive NOTIFY activeChanged)
    Q_PROPERTY(bool animated READ animated WRITE setAnimated NOTIFY animatedChanged)
    Q_PROPERTY(QStringList channels READ channels WRITE setChannels NOTIFY channelsChanged)
    Q_PROPERTY(QVariantList colors READ colors WRITE setColors NOTIFY colorsChanged)
    Q_PROPERTY(bool fill READ fill WRITE setFill NOTIFY fillChanged)
    Q_PROPERTY(bool showGrid READ showGrid WRITE setShowGrid NOTIFY showGridChanged)
    Q_PROPERTY(bool detailPoints READ detailPoints WRITE setDetailPoints NOTIFY detailPointsChanged)
    Q_PROPERTY(QColor gridColor READ gridColor WRITE setGridColor NOTIFY gridColorChanged)
    Q_PROPERTY(qreal lineWidth READ lineWidth WRITE setLineWidth NOTIFY lineWidthChanged)
    // crate-mark options; the defaults keep the stock graph
    Q_PROPERTY(qreal inset READ inset WRITE setInset NOTIFY insetChanged)
    // the antialiased edge each side of a line, in px (stock 1.25)
    Q_PROPERTY(qreal lineFeather READ lineFeather WRITE setLineFeather NOTIFY lineFeatherChanged)
    Q_PROPERTY(QStringList fillChannels READ fillChannels WRITE setFillChannels NOTIFY fillChannelsChanged)
    Q_PROPERTY(bool heads READ heads WRITE setHeads NOTIFY headsChanged)
    Q_PROPERTY(QColor haloColor READ haloColor WRITE setHaloColor NOTIFY haloColorChanged)
    Q_PROPERTY(QString gridStyle READ gridStyle WRITE setGridStyle NOTIFY gridStyleChanged)
    Q_PROPERTY(int sampleCount READ sampleCount NOTIFY sampleCountChanged)
    Q_PROPERTY(int windowSeconds READ windowSeconds NOTIFY sampleCountChanged)
    Q_PROPERTY(qulonglong frameCount READ frameCount)

public:
    explicit SystemGraph(QQuickItem* parent = nullptr);
    ~SystemGraph() override;

    SystemMonitor* source() const { return m_source; }
    void setSource(SystemMonitor* source);
    bool active() const { return m_active; }
    void setActive(bool active);
    bool animated() const { return m_animated; }
    void setAnimated(bool animated);
    const QStringList& channels() const { return m_channels; }
    void setChannels(const QStringList& channels);
    const QVariantList& colors() const { return m_colors; }
    void setColors(const QVariantList& colors);
    bool fill() const { return m_fill; }
    void setFill(bool fill);
    bool showGrid() const { return m_showGrid; }
    void setShowGrid(bool showGrid);
    bool detailPoints() const { return m_detailPoints; }
    void setDetailPoints(bool detailPoints);
    QColor gridColor() const { return m_gridColor; }
    void setGridColor(const QColor& color);
    qreal lineWidth() const { return m_lineWidth; }
    void setLineWidth(qreal width);
    qreal inset() const { return m_inset; }
    void setInset(qreal inset);
    qreal lineFeather() const { return m_lineFeather; }
    void setLineFeather(qreal feather);
    const QStringList& fillChannels() const { return m_fillChannels; }
    void setFillChannels(const QStringList& channels);
    bool heads() const { return m_heads; }
    void setHeads(bool heads);
    QColor haloColor() const { return m_haloColor; }
    void setHaloColor(const QColor& color);
    const QString& gridStyle() const { return m_gridStyle; }
    void setGridStyle(const QString& style);
    int sampleCount() const { return m_sampleCount; }
    int windowSeconds() const;
    qulonglong frameCount() const { return m_frameCount.load(std::memory_order_relaxed); }

signals:
    void sourceChanged();
    void activeChanged();
    void animatedChanged();
    void channelsChanged();
    void colorsChanged();
    void fillChanged();
    void showGridChanged();
    void detailPointsChanged();
    void gridColorChanged();
    void lineWidthChanged();
    void insetChanged();
    void lineFeatherChanged();
    void fillChannelsChanged();
    void headsChanged();
    void haloColorChanged();
    void gridStyleChanged();
    void sampleCountChanged();

protected:
    QSGNode* updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData*) override;
    void itemChange(ItemChange change, const ItemChangeData& data) override;
    bool eventFilter(QObject* watched, QEvent* event) override;

private:
    static constexpr int SampleCapacity = SystemMonitor::HistoryCapacity;

    struct TraceSamples {
        QString channel;
        std::array<float, SampleCapacity> values{};
    };

    void syncFromSource();
    void handleWindowChanged(QQuickWindow* window);
    void updateAnimationState();
    void requestAnimationFrame();
    void markVisualDirty();
    QColor colorForTrace(int trace) const;

    QPointer<SystemMonitor> m_source;
    QMetaObject::Connection m_samplesConnection;
    QMetaObject::Connection m_sourceDestroyedConnection;
    QPointer<QQuickWindow> m_observedWindow;
    QTimer m_frameTimer;
    std::array<qint64, SampleCapacity> m_sampleTimes{};
    QVector<TraceSamples> m_traces;
    int m_sampleCount = 0;
    bool m_active = false;
    bool m_animated = true;
    QStringList m_channels{QStringLiteral("cpu"), QStringLiteral("memory"), QStringLiteral("gpu")};
    QVariantList m_colors{QVariant::fromValue(QColor(Qt::white))};
    bool m_fill = true;
    bool m_showGrid = true;
    bool m_detailPoints = true;
    QColor m_gridColor = Qt::transparent;
    qreal m_lineWidth = 2.0;
    qreal m_inset = -1.0;
    qreal m_lineFeather = 1.25;
    QStringList m_fillChannels;
    bool m_heads = false;
    QColor m_haloColor = Qt::transparent;
    QString m_gridStyle = QStringLiteral("cells");
    std::atomic<qulonglong> m_frameCount{0};
    float m_rateScale = 0.0f;
    qint64 m_lastFrameMs = 0;
};
