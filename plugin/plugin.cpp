#include <QObject>
#include <QQuickItem>
#include <QQuickWindow>
#include <QQmlEngine>
#include <QQmlExtensionPlugin>
#include <KWindowEffects>
#include <QPainter>
#include <QBitmap>
#include <QRegion>
#include <QPointer>
#include <QEvent>
#include <QSet>
#include <QDebug>

class WindowHelper : public QObject {
    Q_OBJECT
public:
    explicit WindowHelper(QObject *parent = nullptr) : QObject(parent) {}

    Q_INVOKABLE void disableBlur(QQuickItem *item) {
        if (!item) return;
        QQuickWindow *win = item->window();
        if (!win) return;
        KWindowEffects::enableBlurBehind(win, false);
        KWindowEffects::enableBackgroundContrast(win, false);
    }

    Q_INVOKABLE void applyMask(QQuickItem *item, double radius, bool blurInside = false) {
        if (!item) return;
        m_item = item;
        m_radius = radius;
        m_blurInside = blurInside;

        QQuickWindow *win = item->window();
        if (win && m_win != win) {
            if (m_win) {
                m_win->removeEventFilter(this);
                disconnect(m_win, nullptr, this, nullptr);
            }
            m_win = win;
            win->installEventFilter(this);
            connect(win, &QQuickWindow::widthChanged, this, &WindowHelper::reapplyMask);
            connect(win, &QQuickWindow::heightChanged, this, &WindowHelper::reapplyMask);
            connect(win, &QQuickWindow::visibleChanged, this, &WindowHelper::reapplyMask);
        }

        if (m_item && !m_itemHooked) {
            m_itemHooked = true;
            connect(item, &QQuickItem::widthChanged, this, &WindowHelper::reapplyMask);
            connect(item, &QQuickItem::heightChanged, this, &WindowHelper::reapplyMask);
            connect(item, &QQuickItem::parentChanged, this, &WindowHelper::reapplyMask);
        }

        reapplyMask();
    }

    Q_INVOKABLE void reapplyMask() {
        if (m_inReapply || !m_item) return;
        m_inReapply = true;

        QQuickWindow *win = m_win ? m_win.data() : m_item->window();
        if (!win) {
            m_inReapply = false;
            return;
        }
        if (!m_win) m_win = win;

        // 1. Enforce fully transparent window clear color
        win->setColor(QColor(Qt::transparent));

        // 2. Disable all borders on PlasmaWindow (removes native frame/shadows)
        win->setProperty("borders", 0);

        // 3. Keep root.parent aligned at (0, 0) matching item dimensions
        QQuickItem *parentItem = m_item->parentItem();
        if (parentItem) {
            if (parentItem->x() != 0) parentItem->setX(0);
            if (parentItem->y() != 0) parentItem->setY(0);
            if (m_item->width() > 0 && parentItem->width() != m_item->width()) {
                parentItem->setWidth(m_item->width());
            }
            if (m_item->height() > 0 && parentItem->height() != m_item->height()) {
                parentItem->setHeight(m_item->height());
            }
        }

        // 4. Neutralize all native Plasma background items
        if (win->contentItem()) {
            neutralizeItems(win->contentItem());
        }

        // 5. Disable KWin compositor blur behind window
        if (!m_blurInside) {
            KWindowEffects::enableBlurBehind(win, false);
            KWindowEffects::enableBackgroundContrast(win, false);
        }

        // 6. Synchronize geometry and mask
        int winW = win->width();
        int winH = win->height();
        if (winW > 0 && winH > 0) {
            int w = m_item->width() > 0 ? (int)m_item->width() : winW;
            int h = m_item->height() > 0 ? (int)m_item->height() : winH;

            QPointF posInWin = m_item->mapToScene(QPointF(0, 0));
            int x = (int)posInWin.x();
            int y = (int)posInWin.y();

            QBitmap bmp(winW, winH);
            bmp.fill(Qt::color0);
            QPainter p(&bmp);
            p.setBrush(Qt::color1);
            p.setPen(Qt::NoPen);
            p.drawRoundedRect(x, y, w, h, m_radius, m_radius);
            p.end();

            QRegion r(bmp);
            win->setMask(r);

            if (m_blurInside) {
                KWindowEffects::enableBlurBehind(win, true, r);
                KWindowEffects::enableBackgroundContrast(win, false);
            }
        }

        m_inReapply = false;
    }

protected:
    bool eventFilter(QObject *watched, QEvent *event) override {
        if (!m_item || !m_win) return false;

        if (watched == m_win) {
            QEvent::Type t = event->type();
            if (t == QEvent::Resize || t == QEvent::Show || t == QEvent::WindowStateChange) {
                QMetaObject::invokeMethod(this, &WindowHelper::reapplyMask, Qt::QueuedConnection);
            }
        }
        return false;
    }

private:
    void neutralizeItems(QQuickItem *parent) {
        if (!parent) return;
        for (QQuickItem *child : parent->childItems()) {
            if (child == m_item) continue;
            if (m_item && child->isAncestorOf(m_item)) {
                child->setX(0);
                child->setY(0);
                neutralizeItems(child);
                continue;
            }

            child->setVisible(false);
            child->setOpacity(0.0);
            child->setProperty("imagePath", "");
            child->setProperty("prefix", "");
            child->setProperty("elementId", "");

            if (!m_hookedItems.contains(child)) {
                m_hookedItems.insert(child);
                connect(child, &QQuickItem::visibleChanged, this, [child]() {
                    if (child && child->isVisible()) child->setVisible(false);
                });
                connect(child, &QQuickItem::opacityChanged, this, [child]() {
                    if (child && child->opacity() > 0.0) child->setOpacity(0.0);
                });
            }

            neutralizeItems(child);
        }
    }

    QPointer<QQuickItem> m_item;
    QPointer<QQuickWindow> m_win;
    QSet<QQuickItem*> m_hookedItems;
    double m_radius = 24.0;
    bool m_blurInside = false;
    bool m_itemHooked = false;
    bool m_inReapply = false;
};

class GnomeQuickSettingsPlugin : public QQmlExtensionPlugin {
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface")
public:
    void registerTypes(const char *uri) override {
        qmlRegisterType<WindowHelper>(uri, 1, 0, "WindowHelper");
    }
};

#include "plugin.moc"
